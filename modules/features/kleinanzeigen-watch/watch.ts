import { existsSync } from "node:fs";
import { appendFile, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { $ } from "zx/core";
import * as z from "zod";

const configPath = "/tank/kleinanzeigen/watches.json";
const seenPath = join(z.string().parse(process.env.STATE_DIRECTORY), "seen");

// The app API namespaces its JSON keys.
const adsKey = "{http://www.ebayclassifiedsgroup.com/schema/ad/v1}ads";

// Berlin, per locations/top-locations.json?q=Berlin. A coarse server-side
// filter only; maxKm is measured from the configured origins.
const berlinLocationId = 3331;
const berlinRadiusKm = 15;

const ConfigSchema = z.object({
  origins: z
    .array(z.object({ name: z.string(), lat: z.number(), lon: z.number() }))
    .nonempty(),
  watches: z
    .array(
      z.object({ query: z.string(), maxPrice: z.number(), maxKm: z.number() }),
    )
    .nonempty(),
});

const LinkSchema = z.object({ rel: z.string(), href: z.string() });
const ValueSchema = z.object({ value: z.string() });

const ResponseSchema = z.object({
  [adsKey]: z.object({
    value: z.object({
      ad: z
        .array(
          z.object({
            id: z.string(),
            title: ValueSchema,
            "ad-address": z
              .object({
                latitude: ValueSchema.optional(),
                longitude: ValueSchema.optional(),
              })
              .optional(),
            price: z
              .object({
                "price-type": ValueSchema,
                amount: z.object({ value: z.number().optional() }).optional(),
              })
              .optional(),
            link: z.array(LinkSchema),
            pictures: z
              .object({
                picture: z.array(z.object({ link: z.array(LinkSchema) })),
              })
              .optional(),
          }),
        )
        .optional(),
    }),
  }),
});

const unescape = (text: string) =>
  text
    .replaceAll("&#x2F;", "/")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&amp;", "&");

const radians = (degrees: number) => (degrees * Math.PI) / 180;

// Great-circle distance
const km = (aLat: number, aLon: number, bLat: number, bLon: number) => {
  const s1 = Math.sin(radians(bLat - aLat) / 2);
  const s2 = Math.sin(radians(bLon - aLon) / 2);
  const a =
    s1 * s1 + Math.cos(radians(aLat)) * Math.cos(radians(bLat)) * s2 * s2;
  return 12742 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

const config = ConfigSchema.parse(
  JSON.parse(await readFile(configPath, "utf8")),
);

// A first run would otherwise fire one notification per existing match; seed
// the state file silently instead.
const seeding = !existsSync(seenPath);
if (seeding) {
  await writeFile(seenPath, "");
  console.log("first run: recording current matches without notifying");
}
const seen = new Set((await readFile(seenPath, "utf8")).split("\n"));

const markSeen = async (id: string) => {
  seen.add(id);
  await appendFile(seenPath, `${id}\n`);
};

let failed = false;
let total = 0;

for (const watch of config.watches) {
  const url = new URL("https://api.kleinanzeigen.de/api/ads.json");
  url.search = new URLSearchParams({
    q: watch.query,
    // 41 newest Berlin ads per query, no paging: at a 5-minute poll a query
    // would have to gain 41 ads in 5 minutes to lose one. The busiest thing
    // measured, a bare "fahrrad" in Berlin, turns over 41 in 26 minutes.
    size: "41",
    sortType: "DATE_DESCENDING",
    includeTopAds: "false",
    locationId: String(berlinLocationId),
    distance: String(berlinRadiusKm),
  }).toString();

  let body: unknown;
  try {
    const response = await fetch(url, {
      headers: {
        Authorization: "Basic YW5kcm9pZDpUYVI2MHBFdHRZ",
        "User-Agent": "okhttp/4.10.0",
        Accept: "application/json",
      },
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    body = await response.json();
  } catch (error) {
    console.error(`${watch.query}: fetch failed: ${error}`);
    failed = true;
    continue;
  }

  const ads = ResponseSchema.parse(body)[adsKey].value.ad ?? [];
  total += ads.length;

  const matches = ads.flatMap((ad) => {
    const lat = ad["ad-address"]?.latitude?.value;
    const lon = ad["ad-address"]?.longitude?.value;
    if (!lat || !lon) return [];

    // Price-on-request is dealer noise; "zu verschenken" is a real 0 EUR and
    // should pass any cap.
    const priceType = ad.price?.["price-type"].value;
    if (priceType !== "SPECIFIED_AMOUNT" && priceType !== "FREE") return [];
    const price = ad.price?.amount?.value ?? 0;

    const nearest = config.origins
      .map((origin) => ({
        name: origin.name,
        km: km(origin.lat, origin.lon, Number(lat), Number(lon)),
      }))
      .reduce((a, b) => (b.km < a.km ? b : a));
    if (price > watch.maxPrice || nearest.km > watch.maxKm) return [];

    const listing = ad.link.find((l) => l.rel === "self-public-website");
    if (!listing) return [];

    return [
      {
        id: ad.id,
        title: unescape(ad.title.value),
        price,
        km: Math.round(nearest.km * 10) / 10,
        origin: nearest.name,
        url: listing.href,
        // teaser is ~4 KB; large and XXL are wasteful for a notification.
        image: ad.pictures?.picture
          .flatMap((picture) => picture.link)
          .find((l) => l.rel === "teaser")?.href,
      },
    ];
  });

  let fresh = 0;

  for (const match of matches) {
    if (seen.has(match.id)) continue;
    fresh++;

    if (seeding) {
      await markSeen(match.id);
      continue;
    }

    console.log(
      `${watch.query}: new ${match.id} - ${match.title} (${match.price} EUR, ${match.km} km from ${match.origin})`,
    );

    // The ntfy clients only preview attachments the server itself hosts; a
    // remote --attach URL renders as a filename. So fetch the photo and
    // upload it. A failed fetch must not cost us the notification.
    let photo: string | undefined;
    if (match.image) {
      try {
        const response = await fetch(match.image, {
          signal: AbortSignal.timeout(15_000),
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        photo = join(
          await mkdtemp(join(tmpdir(), "kleinanzeigen-")),
          "photo.jpg",
        );
        await writeFile(photo, Buffer.from(await response.arrayBuffer()));
      } catch (error) {
        console.error(
          `${watch.query}: photo fetch failed for ${match.id}: ${error}`,
        );
      }
    }

    try {
      await $({
        input: `${match.price} EUR - ${match.km} km from ${match.origin}\n`,
      })`ntfy publish --quiet --title ${match.title} --actions ${`view, Open listing, ${match.url}`} ${photo ? ["--file", photo] : []}`;
      await markSeen(match.id);
    } catch (error) {
      console.error(
        `${watch.query}: notification failed for ${match.id}: ${error}`,
      );
      failed = true;
    }

    if (photo) await rm(join(photo, ".."), { recursive: true, force: true });
  }

  console.log(
    `${watch.query}: ${ads.length} ads, ${matches.length} matching, ${fresh} new`,
  );
}

// Every query coming back empty means the API changed or the app token
// rotated, not that Berlin ran out of listings.
if (total === 0) {
  console.error("no ads returned by any query - API or token likely broken");
  process.exit(1);
}

process.exit(failed ? 1 : 0);

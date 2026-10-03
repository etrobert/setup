{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}

import Data.Aeson (FromJSON, eitherDecode)
import qualified Data.ByteString.Lazy as BL
import Data.List (intercalate)
import Data.Maybe (catMaybes, fromMaybe)
import Data.Time (defaultTimeLocale, formatTime, getCurrentTime, getCurrentTimeZone, utcToLocalTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime, utcTimeToPOSIXSeconds)
import GHC.Generics (Generic)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import System.Process (readProcessWithExitCode)
import Text.Printf (printf)

-- The fields read from the statusline payload; every branch of `rate_limits`
-- and `used_percentage` may be absent per the docs, nothing else is optional.
data Window = Window {used_percentage :: Maybe Double, resets_at :: Maybe Int}
  deriving (Generic, FromJSON)

data Model = Model {display_name :: String} deriving (Generic, FromJSON)

data Limits = Limits {five_hour :: Maybe Window, seven_day :: Maybe Window}
  deriving (Generic, FromJSON)

data Input = Input
  { model :: Model,
    context_window :: Window,
    rate_limits :: Maybe Limits
  }
  deriving (Generic, FromJSON)

red, yellow, green, reset :: String
red = "\ESC[31m"
yellow = "\ESC[33m"
green = "\ESC[32m"
reset = "\ESC[0m"

pctColor :: Int -> String
pctColor pct
  | pct >= 80 = red
  | pct >= 50 = yellow
  | otherwise = ""

-- With a reset time, shows how far ahead of an even burn the window is; the
-- colour then tracks that pace instead of the percentage.
limitSegment :: String -> Int -> Maybe Int -> Double -> String -> IO String
limitSegment label pct Nothing _ _ = pure (pctColor pct ++ label ++ ":" ++ show pct ++ "%" ++ reset)
limitSegment label pct (Just resetTs) window dateFmt = do
  now <- getCurrentTime
  zone <- getCurrentTimeZone
  let reset' = posixSecondsToUTCTime (fromIntegral resetTs)
      remaining = realToFrac (utcTimeToPOSIXSeconds reset' - utcTimeToPOSIXSeconds now)
      elapsedPct = (window - remaining) / window * 100
      pace = if elapsedPct > 0 then fromIntegral pct / elapsedPct else 0 :: Double
      color
        | pace >= 1.1 = red
        | pace >= 0.9 = yellow
        | otherwise = ""
      resetDisplay = formatTime defaultTimeLocale dateFmt (utcToLocalTime zone reset')
  pure (printf "%s%s:%d%% ×%.2f%s (%s)" color label pct pace reset resetDisplay)

main :: IO ()
main = do
  raw <- BL.getContents
  input <- either (\e -> hPutStrLn stderr e >> exitFailure) pure (eitherDecode raw)

  let modelSegment = "[" ++ display_name (model input) ++ "]"

  (_, out, _) <- readProcessWithExitCode "git" ["branch", "--show-current"] ""
  let branchName = concat (lines out)
      branch = if null branchName then Nothing else Just (green ++ branchName ++ reset)

  let ctx = do
        pct <- round <$> used_percentage (context_window input)
        pure (pctColor pct ++ "ctx:" ++ show pct ++ "%" ++ reset)

  let limit label window dateFmt w = case w >>= used_percentage of
        Nothing -> pure Nothing
        Just pct -> Just <$> limitSegment label (round pct) (w >>= resets_at) window dateFmt
  fiveHour <- limit "5h" (5 * 3600) "%H:%M" (rate_limits input >>= five_hour)
  sevenDay <- limit "7d" (7 * 86400) "%a %H:%M" (rate_limits input >>= seven_day)

  -- Sections are separated by |; the two limits within their section by -.
  let limits = intercalate " - " (catMaybes [fiveHour, sevenDay])
      sections = [unwords (catMaybes [Just modelSegment, branch]), fromMaybe "" ctx, limits]
  putStrLn (intercalate " | " (filter (not . null) sections))

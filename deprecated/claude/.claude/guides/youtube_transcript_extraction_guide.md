# YouTube Transcript Extraction & Video Summarization Guide

## Overview
This guide documents the step-by-step process for extracting actual transcripts from YouTube videos and creating comprehensive summaries based on real spoken content rather than video descriptions.

## Prerequisites
- Access to Puppeteer browser automation tools
- YouTube video URL
- TodoWrite tool for tracking progress

## Step-by-Step Process

### 1. Setup and Planning
```
TodoWrite: Create tracking todos
- Extract actual video transcript/captions from YouTube
- Create markdown file with real content summary
```

### 2. Navigate to Video
```
mcp__puppeteer__puppeteer_navigate(url: "https://www.youtube.com/watch?v=VIDEO_ID")
```

### 3. Handle Cookie Consent & Popups
YouTube often shows cookie consent screens that must be handled first.

**Take screenshot to assess situation:**
```
mcp__puppeteer__puppeteer_screenshot(name: "initial_page")
```

**Handle cookie consent:**
```javascript
mcp__puppeteer__puppeteer_evaluate:
(() => {
  const buttons = document.querySelectorAll('button');
  for (let button of buttons) {
    if (button.textContent.toLowerCase().includes('accept') || 
        button.textContent.toLowerCase().includes('agree')) {
      button.click();
      return 'Clicked accept button';
    }
  }
  return 'No accept button found';
})();
```

### 4. Skip Ads (if present)
Ads may prevent access to video features.

**Look for skip buttons:**
```javascript
mcp__puppeteer__puppeteer_evaluate:
(() => {
  const skipElements = document.querySelectorAll('*');
  for (let element of skipElements) {
    const text = element.textContent;
    if (text && (text.includes('Skip') || text.includes('überspringen'))) {
      if (element.tagName === 'BUTTON' || element.getAttribute('role') === 'button') {
        element.click();
        return 'Clicked skip: ' + text;
      }
    }
  }
  return 'No skip button found';
})();
```

### 5. Access Transcript Panel
**Method 1: Direct transcript button click**
```javascript
mcp__puppeteer__puppeteer_evaluate:
(() => {
  const buttons = document.querySelectorAll('button');
  for (let button of buttons) {
    if (button.getAttribute('aria-label') === 'Show transcript' || 
        button.textContent === 'Show transcript' ||
        button.getAttribute('aria-label') === 'Transcript') {
      button.click();
      return 'Clicked transcript button';
    }
  }
  return 'Could not find transcript button';
})();
```

**Method 2: Check for transcript elements**
```javascript
mcp__puppeteer__puppeteer_evaluate:
(() => {
  const allElements = document.querySelectorAll('*');
  const transcriptElements = [];
  
  for (let element of allElements) {
    const text = element.textContent || '';
    const ariaLabel = element.getAttribute('aria-label') || '';
    
    if ((text.toLowerCase().includes('transcript') || ariaLabel.toLowerCase().includes('transcript')) && 
        (element.tagName === 'BUTTON' || element.getAttribute('role') === 'button')) {
      transcriptElements.push({
        tag: element.tagName,
        text: text.substring(0, 100),
        ariaLabel: ariaLabel
      });
    }
  }
  
  return {
    foundElements: transcriptElements.length,
    elements: transcriptElements
  };
})();
```

### 6. Extract Transcript Content
Once transcript panel is open, extract the actual content:

**Small chunks extraction (to avoid token limits):**
```javascript
mcp__puppeteer__puppeteer_evaluate:
(() => {
  // Get first part of transcript that's currently visible
  const visibleText = [];
  
  // Look for timestamp and text pairs in current view
  const elements = document.querySelectorAll('[class*="segment"], .ytd-transcript-segment-renderer');
  
  for (let i = 0; i < Math.min(10, elements.length); i++) {
    const element = elements[i];
    const text = element.textContent.trim();
    if (text && text.length > 10) {
      visibleText.push(text);
    }
  }
  
  if (visibleText.length === 0) {
    // Fallback - get visible transcript text from panel
    const panel = document.querySelector('.ytd-engagement-panel-section-list-renderer');
    if (panel) {
      const text = panel.textContent.trim();
      return {
        status: 'Got panel text',
        content: text.substring(0, 2000),
        fullLength: text.length
      };
    }
  }
  
  return {
    status: 'Got segments',
    segments: visibleText.slice(0, 10),
    totalVisible: visibleText.length
  };
})();
```

### 7. Scroll for More Content (if needed)
If transcript is long, you may need to scroll through the transcript panel to get all content.

### 8. Create Comprehensive Summary
Based on the extracted transcript, create a structured markdown summary:

**Template Structure:**
```markdown
# YouTube Video Summary: [TITLE]

## Video Information
- **Title**: [From actual page]
- **Channel**: [Channel name]
- **Subscribers**: [Sub count]
- **Upload Date**: [Date]
- **Views**: [View count]
- **URL**: [Original URL]

## Overview
[Brief description based on actual content]

## Key Topics/Framework
[Extract main structure from transcript]

## Detailed Content
[Based on actual quotes and insights from transcript]

## Main Takeaways
[Key actionable insights from what was actually said]
```

## Common Issues & Solutions

### Issue: Cookie Consent Blocking
**Solution:** Always handle cookie consent first before attempting to access video features.

### Issue: Ads Preventing Access
**Solution:** Look for and click skip buttons, or wait for ads to finish.

### Issue: Transcript Panel Not Opening
**Solutions:**
1. Try different selectors for transcript buttons
2. Scroll down to description area
3. Look for "More actions" menu that might contain transcript option

### Issue: Large Transcript Exceeding Token Limits
**Solutions:**
1. Extract in smaller chunks (10 segments at a time)
2. Focus on key sections first
3. Summarize as you extract rather than getting full transcript

### Issue: No Transcript Available
**Fallback:** Some videos don't have auto-generated transcripts. In this case, rely on video description and visible content analysis.

## Quality Checks

### Verify Real Content Extraction
- Check that summary contains specific quotes from speaker
- Ensure insights reflect actual spoken content, not just video metadata
- Include timestamps where relevant
- Capture speaker's specific frameworks, examples, and advice

### Content Accuracy
- Cross-reference extracted content with what you can see in screenshots
- Ensure main points align with transcript segments
- Include specific numbers, examples, and frameworks mentioned

## Example Use Cases

1. **Educational Content Analysis**: Extract teaching frameworks, specific advice, step-by-step processes
2. **Interview Summaries**: Capture key insights, quotes, and discussion points
3. **Tutorial Documentation**: Document actual steps, tools, and techniques demonstrated
4. **Business Advice**: Extract actionable strategies, frameworks, and real examples

## Tools Required

- `mcp__puppeteer__puppeteer_navigate`
- `mcp__puppeteer__puppeteer_screenshot`  
- `mcp__puppeteer__puppeteer_click`
- `mcp__puppeteer__puppeteer_evaluate`
- `TodoWrite` for progress tracking
- `Write` for creating summary document

## Success Metrics

- Summary based on actual spoken words, not video description
- Includes specific quotes and examples from speaker
- Captures main frameworks and structured content
- Provides actionable insights from real content
- Maintains speaker's terminology and key concepts
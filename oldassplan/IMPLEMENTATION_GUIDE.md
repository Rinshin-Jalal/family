# StoryRd - Complete Implementation Guide

## 5 WAYS TO COLLECT STORIES

```
1. 🎙️ AUDIO RECORDING
   - In-app recording
   - Call family member and record
   - Upload existing audio files

2. ✍️ WRITTEN STORIES  
   - Type/paste text
   - Best for: Memory, notes, direct writing

3. 📷 PHOTO UPLOAD
   - Take photo of handwritten notes
   - OCR transcription (AI reads handwriting)
   - Best for: Old diaries, letters, recipes

4. 📄 DOCUMENT UPLOAD
   - PDF, TXT, DOCX files
   - Parse and extract text
   - Best for: Digital documents

5. 🎭 VOICE CLONING (MAGIC!)
   - Upload written story + 30 sec voice sample
   - AI clones voice
   - Hear them read their own words!
```

## KEY FEATURES

### Voice Cloning
- Written story input
- 30 sec voice sample needed
- Clone grandfather's voice
- Grandpa reads his own diary entries!

### Photo OCR
- Take photo of handwritten notes
- AI transcribes handwriting
- Convert to searchable story
- Preserve original photo

### Document Parsing
- PDF support
- Plain text files
- Word documents
- Extract and organize

## COLLECTION FLOW

```
User selects method:
├─ Audio → Record/Upload
├─ Written → Type/Paste
├─ Photo → Camera/ Gallery → OCR
├─ Document → File Picker → Parse
└─ Voice Clone → Written + Sample → Clone
```

## CONVERSION TRIGGERS

| Method | Emotional Impact | Ease | % Users |
|--------|-----------------|------|---------|
| Audio Recording | High | Medium | 40% |
| Written Stories | Medium | Easy | 25% |
| Photo Upload | Medium | Easy | 20% |
| Document Upload | Low | Easy | 10% |
| Voice Clone | VERY HIGH | Medium | 5% |

## VOICE CLONING IS THE KILLER FEATURE

"Grandpa passed in 2020. Now my kids hear him read his own diary entries."

This single feature makes StoryRd unique and emotionally powerful.

## TECHNICAL REQUIREMENTS

### Backend
- OCR service (Google Vision or similar)
- Document parsing (PDFKit, antiword)
- Voice cloning API (ElevenLabs, OpenAI)
- Storage for voice samples

### iOS
- Camera integration
- Photo library access
- Document picker
- Audio recording

### Database
```sql
ALTER TABLE stories ADD COLUMN collection_method VARCHAR(20);
-- audio, written, photo, document, voice_clone

ALTER TABLE stories ADD COLUMN is_voice_cloned BOOLEAN DEFAULT FALSE;
ALTER TABLE stories ADD COLUMN original_voice_sample_url TEXT;
```

## ONBOARDING FLOW

### Phase 1: Hook (Screens 1-10)
- Welcome
- Question/Audio demos
- Written story example
- Photo example
- Voice clone example
- Kids/Podcast

### Phase 2: Pitch (Screens 11-20)
- Problem: Stories lost
- Opportunity: Written diaries exist!
- Solution
- How it works (all 5 methods)
- Social proof
- Offer

### Phase 3: Family Setup (Screens 21-28)
- Create/Join family
- Name, Role, Invite members
- Ready to go

### Phase 4: First Story (Screens 29-45)
- How to collect (5 options)
- Each method flow
- Record tips
- Processing
- Story reveal
- Share/upsell

## SAMPLE SCREENS

### Screen: How To Collect
Shows 5 cards with icons, descriptions, "Best for" info
Each leads to specific collection method

### Screen: Voice Clone Magic
- Step 1: Upload written story
- Step 2: Voice sample (30 sec)
- Preview: "Written → Their Voice Reading!"
- Example quote in grandfather's voice

### Screen: Photo Upload
- Shows what to photograph:
  - Handwritten diaries
  - Letters from grandparents
  - Old recipes
  - Family documents
- AI reads handwriting
- Creates story

## SUCCESS METRICS

- Stories collected per user
- Voice clones created
- Photo uploads
- Written stories uploaded
- Family members invited

## NEXT STEPS

1. Fix code dependencies
2. Implement OCR service
3. Add document parsing
4. Integrate voice cloning API
5. Build UI screens
6. Test collection flows
7. Launch with all 5 methods


-- =========================================================================
-- STORYRIDE - SEED DATA FOR TESTING
-- =========================================================================
-- Add test stories with varied content for testing semantic search
-- =========================================================================

-- First, get a family_id to use (replace with actual family_id from your DB)
-- SELECT id FROM families LIMIT 1;

-- Example stories with rich content for semantic search testing
-- Run each block separately or adjust family_id as needed

-- =========================================================================
-- STORY 1: Love and Marriage Advice
-- =========================================================================
-- Query: "advice about love", "relationship wisdom", "marriage tips"
INSERT INTO stories (id, family_id, title, summary_text, voice_count, is_completed, created_at)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    (SELECT id FROM families LIMIT 1),
    'Grandma and Grandpa''s 50th Anniversary',
    'Grandma always says that marriage is not about finding someone who never makes you angry, but finding someone who can handle your bad days. She learned that love is a choice you make every single morning when you wake up next to the same person. Grandpa adds that communication is key - they never go to bed angry, even if it means staying up until 3am talking through an argument. The secret? Both learned to listen to understand, not just to respond.',
    2,
    true,
    NOW() - INTERVAL '10 days'
);

INSERT INTO responses (id, story_id, user_id, source, transcription_text, processing_status, created_at)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    (SELECT id FROM profiles LIMIT 1),
    'app_audio',
    'When I married your grandfather 50 years ago, I was only 22 years old and scared to death. My mother told me something that I''ve carried with me every day since: marriage is not about finding a perfect person, but learning to love an imperfect person perfectly. There were times we wanted to give up, times we said terrible things to each other. But we always came back to the question: do I want to spend my life with this person? And the answer was always yes. The secret to a long marriage is simple - choose each other every single day.',
    'completed',
    NOW() - INTERVAL '10 days'
);

-- =========================================================================
-- STORY 2: Job Loss and Resilience
-- =========================================================================
-- Query: "job loss advice", "career hardship", "how to handle being fired"
INSERT INTO stories (id, family_id, title, summary_text, voice_count, is_completed, created_at)
VALUES (
    '33333333-3333-3333-3333-333333333333',
    (SELECT id FROM families LIMIT 1),
    'When Dad Lost His Job',
    'Dad was laid off from his engineering job of 20 years during the recession. The whole family was scared - we didn''t know how we would pay the mortgage. But Dad turned it into a learning experience. He told us that setbacks are just setups for comebacks. He started his own consulting business and eventually made more money than before. His advice to us: never let your job define your worth, and always have a backup plan.',
    2,
    true,
    NOW() - INTERVAL '20 days'
);

INSERT INTO responses (id, story_id, user_id, source, transcription_text, processing_status, created_at)
VALUES (
    '44444444-4444-4444-4444-444444444444',
    '33333333-3333-3333-3333-333333333333',
    (SELECT id FROM profiles LIMIT 1),
    'app_audio',
    'I remember the day I got laid off like it was yesterday. I walked into work and they called me into a conference room. Twenty years of my life, gone in a 10-minute meeting. I drove home in silence, sitting in the garage for an hour before I could go inside. But you know what? That was the best thing that ever happened to me. I was so comfortable, so complacent. Being forced out of my comfort zone made me realize how much more I was capable of. My advice to anyone going through a job loss: this is not the end, it''s just a plot twist in your story. Embrace the uncertainty - something better is coming.',
    'completed',
    NOW() - INTERVAL '20 days'
);

-- =========================================================================
-- STORY 3: Family Traditions
-- =========================================================================
-- Query: "family traditions", "holiday memories", "family gatherings"
INSERT INTO stories (id, family_id, title, summary_text, voice_count, is_completed, created_at)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    (SELECT id FROM families LIMIT 1),
    'Sunday Dinners at Grandma''s House',
    'Every Sunday without fail, our entire extended family gathered at Grandma''s house for dinner. The smell of her pot roast would fill the house by noon, and the whole neighborhood knew it was Sunday. These weekly gatherings taught us the importance of making time for family, no matter how busy life gets. Even now, decades later, we still try to have Sunday dinners, though some of us have to join via video call.',
    2,
    true,
    NOW() - INTERVAL '30 days'
);

INSERT INTO responses (id, story_id, user_id, source, transcription_text, processing_status, created_at)
VALUES (
    '66666666-6666-6666-6666-666666666666',
    '55555555-5555-5555-5555-555555555555',
    (SELECT id FROM profiles LIMIT 1),
    'app_audio',
    'I grew up in a small house, but on Sundays it felt like a mansion because it was so full of people. My grandparents, aunts, uncles, cousins - everyone came. There were at least 15 of us every single Sunday. And the food! Grandma would start cooking on Saturday night because she had to feed all of us. I remember my cousins and I would play in the backyard while the adults talked in the kitchen. Those Sundays taught me that family isn''t just blood - it''s showing up, week after week, year after year. Even when I moved across the country, I still called Grandma every Sunday at 5pm. It was our tradition.',
    'completed',
    NOW() - INTERVAL '30 days'
);

-- =========================================================================
-- STORY 4: Overcoming Hardship
-- =========================================================================
-- Query: "overcoming hardship", "hard times", "resilience", "staying positive"
INSERT INTO stories (id, family_id, title, summary_text, voice_count, is_completed, created_at)
VALUES (
    '77777777-7777-7777-7777-777777777777',
    (SELECT id FROM families LIMIT 1),
    'The Year We Lost Everything',
    'When the bank foreclosed on our house, we had to move in with relatives. It was humbling and devastating. But that year taught our family what truly matters. We learned that possessions can be replaced, but family cannot. My parents worked two jobs each to get back on their feet, and they never complained. Their resilience taught me that hard times don''t last forever, but family does.',
    2,
    true,
    NOW() - INTERVAL '40 days'
);

INSERT INTO responses (id, story_id, user_id, source, transcription_text, processing_status, created_at)
VALUES (
    '88888888-8888-8888-8888-888888888888',
    '77777777-7777-7777-7777-777777777777',
    (SELECT id FROM profiles LIMIT 1),
    'app_audio',
    'I was 16 years old when we lost our house. I remember coming home from school and seeing my dad sitting in the car, just staring at the garage door. He couldn''t look at me. That image still breaks my heart. We moved in with my aunt and uncle - four adults, three kids, two bedrooms. It was chaos. But you know what I remember most? The laughter. Despite everything, our family found reasons to laugh. My parents worked so hard to give us a normal life again. It took three years, but we bought another house. When we got the keys, my dad just cried. Not sad tears - proud tears. He said we made it because we stayed together. That''s when I understood: family is your anchor in the storm.',
    'completed',
    NOW() - INTERVAL '40 days'
);

-- =========================================================================
-- STORY 5: Childhood Memories
-- =========================================================================
-- Query: "childhood memories", "growing up", "what was it like"
INSERT INTO stories (id, family_id, title, summary_text, voice_count, is_completed, created_at)
VALUES (
    '99999999-9999-9999-9999-999999999999',
    (SELECT id FROM families LIMIT 1),
    'Summers at the Lake House',
    'Every summer, my family would pack up the station wagon and drive four hours to a tiny lake house that had been in my family for three generations. There was no TV, no internet, no air conditioning - just the lake, the woods, and each other. We fished, we swam, we told stories. Those simple summers shaped who I am today. I learned to find joy in simplicity and to put away the distractions of modern life.',
    2,
    true,
    NOW() - INTERVAL '50 days'
);

INSERT INTO responses (id, story_id, user_id, source, transcription_text, processing_status, created_at)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '99999999-9999-9999-9999-999999999999',
    (SELECT id FROM profiles LIMIT 1),
    'app_audio',
    'I wish kids today could experience what I experienced growing up. No screens, no social media, just pure freedom. My brother and I would wake up at sunrise and spend the entire day outside until our moms called us in for dinner. We built forts, we caught frogs, we caught fireflies in jars. At night, we''d lie on the dock and count shooting stars. My grandfather would sit on the porch in his rocking chair and tell us stories about growing up during the Great Depression. He said those stories shaped his entire life. I feel so blessed that my children got to experience some of those summers too, though technology had already started taking over by then. The lake house is gone now, but those memories will last forever.',
    'completed',
    NOW() - INTERVAL '50 days'
);

-- =========================================================================
-- STORY 6: Advice for Children
-- =========================================================================
-- Query: "advice for my kids", "what to tell my children", "wisdom for the young"
INSERT INTO stories (id, family_id, title, summary_text, voice_count, is_completed, created_at)
VALUES (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    (SELECT id FROM families LIMIT 1),
    'What I Want My Grandchildren to Know',
    'If I could give my grandchildren one piece of advice, it would be this: be kind, work hard, and don''t take yourself too seriously. Life will knock you down - that''s guaranteed. But getting back up is optional, and you always have a choice. I''ve seen war, I''ve lost loved ones, I''ve struggled financially - but the one thing that got me through everything was my family and my faith. Money comes and goes, jobs come and go, but family is forever.',
    2,
    true,
    NOW() - INTERVAL '60 days'
);

INSERT INTO responses (id, story_id, user_id, source, transcription_text, processing_status, created_at)
VALUES (
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    (SELECT id FROM profiles LIMIT 1),
    'app_audio',
    'I''ve lived a long life - 82 years now - and if I could sit down with my grandchildren and pass on everything I''ve learned, here''s what I''d say: First, kindness is a muscle. Use it or lose it. The smallest act of kindness can change someone''s entire day. Second, fail fast and learn faster. Don''t be afraid of making mistakes - that''s how you grow. Third, surrounding yourself with good people is the greatest wealth. I''ve had rich friends who were miserable and poor friends who were joyful. The difference was always their relationships. Fourth, take care of your health - you only get one body. And finally, say I love you every chance you get. Life is too short to leave things unsaid.',
    'completed',
    NOW() - INTERVAL '60 days'
);

-- =========================================================================
-- STORY 7: Immigration Story
-- =========================================================================
-- Query: "immigration story", "coming to america", "starting over"
INSERT INTO stories (id, family_id, title, summary_text, voice_count, is_completed, created_at)
VALUES (
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    (SELECT id FROM families LIMIT 1),
    'Coming to America with $200',
    'My parents left everything they knew - their home, their language, their family - to come to America for a better life. They arrived with two suitcases and $200. They didn''t speak English, they had no connections, and they had to start from absolute zero. But they worked harder than anyone I''ve ever known. Within 10 years, they had a small business and a house. Their sacrifice taught me that with determination and hard work, anything is possible.',
    2,
    true,
    NOW() - INTERVAL '70 days'
);

INSERT INTO responses (id, story_id, user_id, source, transcription_text, processing_status, created_at)
VALUES (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    (SELECT id FROM profiles LIMIT 1),
    'app_audio',
    'I was only 7 years old when we left our home country. I remember the plane ride like it was yesterday - the smells, the sounds, the fear. I didn''t speak a word of English. My first day of school, I ate lunch alone in the bathroom because I was too scared to sit with anyone. But my parents never complained, never regretted their decision. They said the hardest part was leaving family behind, not the language barrier or the cultural differences. They built a new life from nothing, and they did it with grace and gratitude. Every time I complain about something in America, my dad reminds me: this is the country that gave us opportunities we never would have had. Never take that for granted.',
    'completed',
    NOW() - INTERVAL '70 days'
);

-- =========================================================================
-- Add story embeddings for semantic search testing
-- =========================================================================
-- Note: These are placeholder embeddings - in production, generate real embeddings
-- The embeddings module will generate proper ones when stories are created

-- =========================================================================
-- Add some quote cards
-- =========================================================================
-- Quote cards depend on families - skipped for now

-- =========================================================================
-- HOW TO USE THESE TEST STORIES
-- =========================================================================
-- 
-- 1. Run this seed file:
--    supabase db reset && supabase db push
--    
-- 2. Or run just this file:
--    psql -f seed.sql
--
-- 3. Test semantic search with queries like:
--    - "advice about love"
--    - "how to handle job loss"  
--    - "family traditions"
--    - "overcoming hard times"
--    - "immigration story"
--    - "what to tell my children"
--
-- 4. The stories cover different topics for comprehensive testing:
--    - Love/Marriage (Story 1)
--    - Career/Job Loss (Story 2)
--    - Family Traditions (Story 3)
--    - Resilience/Hardship (Story 4)
--    - Childhood Memories (Story 5)
--    - Life Advice (Story 6)
--    - Immigration (Story 7)
-- =========================================================================

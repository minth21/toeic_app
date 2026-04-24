-- Standardize TOEIC Question Numbering (Global 1-200)
-- DANGER: This updates all existing Question records.

BEGIN;

-- 1. Temporary table to hold standard ranges
CREATE TEMP TABLE part_ranges (
    part_number INT PRIMARY KEY,
    start_num INT,
    end_num INT
);

INSERT INTO part_ranges (part_number, start_num, end_num) VALUES
(1, 1, 6),
(2, 7, 31),
(3, 32, 70),
(4, 71, 100),
(5, 101, 130),
(6, 131, 146),
(7, 147, 200);

-- 2. Update Question Numbers based on Part Type
-- Use ROW_NUMBER to maintain existing relative order if multiple questions exist
WITH ReindexedQuestions AS (
    SELECT 
        q.id,
        p.partNumber,
        pr.start_num + ROW_NUMBER() OVER (PARTITION BY q.partId ORDER BY q.questionNumber, q.createdAt) - 1 as new_number
    FROM "Question" q
    JOIN "Part" p ON q.partId = p.id
    JOIN part_ranges pr ON p.partNumber = pr.part_number
)
UPDATE "Question"
SET "questionNumber" = rq.new_number
FROM ReindexedQuestions rq
WHERE "Question".id = rq.id;

-- 3. Cleanup
DROP TABLE part_ranges;

COMMIT;

-- Verify check:
-- SELECT p."partNumber", MIN(q."questionNumber"), MAX(q."questionNumber"), COUNT(*) 
-- FROM "Question" q JOIN "Part" p ON q."partId" = p."id" 
-- GROUP BY p."partNumber" ORDER BY p."partNumber";

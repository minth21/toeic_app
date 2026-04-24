-- Standardize TOEIC Question Numbers (1-200 Global Index)
-- This script re-indexes all questions based on their Part number.

BEGIN;

-- 1. Create a temporary mapping of global start numbers for each part
CREATE TEMP TABLE part_ranges (
    part_number INT,
    start_index INT
);

INSERT INTO part_ranges (part_number, start_index) VALUES
(1, 1),   -- Part 1: 1-6
(2, 7),   -- Part 2: 7-31
(3, 32),  -- Part 3: 32-70
(4, 71),  -- Part 4: 71-100
(5, 101), -- Part 5: 101-130
(6, 131), -- Part 6: 131-146
(7, 147); -- Part 7: 147-200

-- 2. Update Question.questionNumber using a window function partitioned by partId
-- We order by current questionNumber to maintain the same relative sequence
WITH NewIndices AS (
    SELECT 
        q.id,
        pr.start_index + (ROW_NUMBER() OVER (PARTITION BY q."partId" ORDER BY q."questionNumber", q."id") - 1) as new_number
    FROM "Question" q
    JOIN "Part" p ON q."partId" = p.id
    JOIN part_ranges pr ON p."partNumber" = pr.part_number
)
UPDATE "Question"
SET "questionNumber" = ni.new_number
FROM NewIndices ni
WHERE "Question".id = ni.id;

-- 3. Cleanup
DROP TABLE part_ranges;

COMMIT;

import { calculateRawToeicScore } from './src/utils/score.util';

function verify() {
    console.log('--- Verifying Official TOEIC Score Mapping ---');
    
    const tests = [
        // Listening
        { type: 'LISTENING' as const, correct: 0,   expected: 5 },
        { type: 'LISTENING' as const, correct: 6,   expected: 40 },
        { type: 'LISTENING' as const, correct: 25,  expected: 135 },
        { type: 'LISTENING' as const, correct: 50,  expected: 260 },
        { type: 'LISTENING' as const, correct: 75,  expected: 385 },
        { type: 'LISTENING' as const, correct: 76,  expected: 395 }, // Gap jump check
        { type: 'LISTENING' as const, correct: 100, expected: 495 },
        
        // Reading
        { type: 'READING' as const, correct: 0,   expected: 5 },
        { type: 'READING' as const, correct: 1,   expected: 5 },
        { type: 'READING' as const, correct: 3,   expected: 10 },
        { type: 'READING' as const, correct: 30,  expected: 145 },
        { type: 'READING' as const, correct: 50,  expected: 245 },
        { type: 'READING' as const, correct: 75,  expected: 370 },
        { type: 'READING' as const, correct: 100, expected: 495 },
    ];

    let allPassed = true;
    for (const test of tests) {
        const actual = calculateRawToeicScore(test.correct, test.type);
        if (actual === test.expected) {
            console.log(`✅ [${test.type}] Correct: ${test.correct} -> Score: ${actual} (PASS)`);
        } else {
            console.log(`❌ [${test.type}] Correct: ${test.correct} -> Score: ${actual} (FAILED, expected ${test.expected})`);
            allPassed = false;
        }
    }

    if (allPassed) {
        console.log('\n🌟 SUCCESS: All mapping points verified against official photos.');
    } else {
        console.log('\n⚠️ ERROR: Some score points do not match.');
    }
}

verify();

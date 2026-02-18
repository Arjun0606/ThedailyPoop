import wordListData from "./words-enable1.json";

const WORD_SET: Set<string> = new Set(wordListData as string[]);

export function isValidEnglishWord(word: string): boolean {
  return WORD_SET.has(word.toLowerCase());
}

function scoreWord(word: string): number {
  const len = word.length;
  if (len <= 2) return 0;
  if (len === 3) return 1;
  if (len === 4) return 3;
  if (len === 5) return 5;
  if (len === 6) return 8;
  if (len === 7) return 12;
  return 15; // 8+
}

/**
 * Given an array of available letters, find ALL valid English words
 * that can be formed using those letters (each letter used at most
 * as many times as it appears in the array).
 *
 * Returns a map of word → point value.
 */
export function findAllValidWords(
  letters: string[]
): Record<string, number> {
  const letterFreq: Record<string, number> = {};
  for (const l of letters) {
    letterFreq[l.toLowerCase()] = (letterFreq[l.toLowerCase()] ?? 0) + 1;
  }

  const result: Record<string, number> = {};

  for (const word of WORD_SET) {
    if (word.length < 3 || word.length > letters.length) continue;

    const wordFreq: Record<string, number> = {};
    for (const c of word) {
      wordFreq[c] = (wordFreq[c] ?? 0) + 1;
    }

    let valid = true;
    for (const [char, count] of Object.entries(wordFreq)) {
      if ((letterFreq[char] ?? 0) < count) {
        valid = false;
        break;
      }
    }

    if (valid) {
      result[word] = scoreWord(word);
    }
  }

  return result;
}

/**
 * Check if a key word is suitable for Word Drop:
 * - Exists in dictionary
 * - Has at least 15 valid sub-words from its letters
 */
export function isGoodKeyWord(word: string): boolean {
  if (!isValidEnglishWord(word)) return false;
  const letters = word.toLowerCase().split("");
  const validWords = findAllValidWords(letters);
  return Object.keys(validWords).length >= 15;
}

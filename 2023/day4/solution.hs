module Main where
import Data.Char (isSpace)
phoenix a b c d = a (b d) (c d)
dove a b c d = a (b c) (b d)
warbler a b = a b b
infixr 9 ...
(...) = (.).(.)
main = interact solution2
-- ======================== SOLUTION 1 ============================= --
score :: Int -> Int
score = round . inner . fromIntegral
    where inner :: Float -> Float
          inner 0 = 0.0
          inner x = 2 ** (x - 1)

cardContents :: String -> ([Int], [Int])
cardContents = uncurry (dove (,) (map process . words))
         . fmap (drop 1) . span (/='|')
         . tail . snd . span (/=':') 
    where process = read . filter (not . isSpace)

test = uncurry woob
    where woob c b = filter (flip elem b) c

solution1 = show . sum
          . map (score . length . test . cardContents)
          . lines
-- ======================== SOLUTION 2 ============================= --

-- comput: Card -> [Id]
-- magic: [Card] -> [Id]

incro 0 = []
incro x = x : incro (x - 1)

card :: String -> (Int, ([Int], [Int]))
card = phoenix (,) cardId cardContents

cardId = read . filter (not . isSpace)
       . drop (length "Card ") . fst . span (/=':')

testInd :: (Int, ([Int], [Int])) -> (Int, [Int])
testInd (cardId, trito) = let result = (length . test) trito
                          in (cardId, (map (+cardId) . incro) result)

magic :: Int -> [[Int]] -> Int
magic = length ... filter . elem

-- we score a card, multiply by occurance, add occurance

occurance :: Int -> [Int] -> Int
occurance = length ... filter . (==)

reoccur 0 xs = []
reoccur x xs = xs ++ reoccur (x - 1) xs

reduce :: [Int] -> (Int, [Int]) -> [Int] 
reduce occ (card, gets) = occ ++ reoccur (occurance card occ) gets

process = phoenix (foldl reduce . incro) (flip (-) 1 . length) id 

spread :: [a -> b] -> a -> [b]
spread [] _ = []
spread (f:fs) x = f x : spread fs x

-- spread . flip occurance (incro mx) 

troot = phoenix (spread . map occurance) (incro . maximum) (id)

solution2 = phoenix (\x y -> x ++ " : " ++ y) (show . length) (show . troot)
          . process
          . map (testInd . card) . lines



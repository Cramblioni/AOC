module Main where
import Data.Char (isDigit)
import Data.List (singleton)
main = interact solution2

--------------------------------- Solution 2 ----------------------------------
ends (x:[])   = [x, x]
ends (x:y:[]) = [x, y]
ends (x:_:xs) = ends (x:xs)

solution1 = show . foldr ((+) . read) 0 . map (ends . filter isDigit) . lines

--------------------------------- Solution 2 ----------------------------------
startsWith (x:xs) (y:ys) | x == y    = startsWith xs ys
                         | otherwise = False
startsWith [] _ = True
startsWith _ [] = False

parse :: String -> Maybe (String, Char)
parse (head:tail) | isDigit head = Just (tail, head)
parse body | startsWith "one"   body = Just (tail body, '1')
           | startsWith "two"   body = Just (tail body, '2')
           | startsWith "three" body = Just (tail body, '3')
           | startsWith "four"  body = Just (tail body, '4')
           | startsWith "five"  body = Just (tail body, '5')
           | startsWith "six"   body = Just (tail body, '6')
           | startsWith "seven" body = Just (tail body, '7')
           | startsWith "eight" body = Just (tail body, '8')
           | startsWith "nine"  body = Just (tail body, '9')
           | [] == body = Nothing
           | otherwise = let (_:tail) = body in parse tail
parseMany = maybe [] (\(i', x) -> x : parseMany i') . parse  
-- solution2 = unlines . map (ends . parseMany) . lines
solution2 = show . foldr ((+) . read) 0 . map (ends . parseMany) . lines

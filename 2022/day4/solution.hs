module Main where
main = solution2

data Range = Range Int Int
bounds :: Range -> Range -> Bool
bounds (Range s1 e1) (Range s2 e2) = s2 >= s1 && e2 <= e1

combine :: (a -> a -> Bool) -> (Bool -> Bool -> Bool) -> a -> a -> Bool
combine f c x y = c (f x y) (f y x)

parseRange :: String -> Range
parseRange = (\(x,y)->Range (read x) (read y)) . fmap tail . span (/='-')
parsePair :: String -> (Range, Range)
parsePair = (\(x, y) -> (parseRange x, parseRange y)) . fmap tail . span (/=',')

doLine1 =(\(x, y) -> combine bounds (||) x y) . parsePair
solution1 = interact $ show . length . filter doLine1 . lines

overlaps :: Range -> Range -> Bool
overlaps (Range s1 e1) (Range s2 e2) = (s2 >= s1 && s2 <= e1)
                                    || (e2 >= s1 && e2 <= e1)

doLine2 =(\(x, y) -> combine overlaps (||) x y) . parsePair
solution2 = interact $ show . length . filter doLine2 . lines
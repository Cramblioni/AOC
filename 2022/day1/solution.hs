module Main where

-- split string by lines -> split list by empty
-- -> sum each sublist -> get the max

chunk :: [String] -> [[String]]
chunk = f [[]]
    where f acc [] = acc
          f acc ("": xs) = f ([] : acc) xs
          f (c:t) (x: xs) = f ((x : c) : t) xs

magic :: [[String]] -> [Int]
magic = map (sum . map read)
-- solution to part 1
-- main = interact $ show . foldr max 0 . magic . chunk . lines

-- to get the list of totals :: magic . chunk . lines


-- filling a list sorting it with one iteration of bubble sort
-- then taking the first `wl` from that list
window :: Int -> [Int] -> [Int]
window wl = f []
    where f buff [] = buff
          f buff (x:xs) = f ((take wl . bbsort)  (x : buff)) xs
          bbsort (x:y:xs) = if x > y then x : bbsort (y: xs)
                                     else y : bbsort (x: xs)
          bbsort [x] = [x]

--solution to part 2
main = interact $ show . sum . window 3 . magic . chunk . lines
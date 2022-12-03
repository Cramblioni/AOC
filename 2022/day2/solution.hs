module Main where

data Move = Rock | Paper | Scissors

rate :: Move -> Int
rate Rock     = 1
rate Paper    = 2
rate Scissors = 3

toScore :: Move -> Move -> Int
toScore Rock     y = case y of
                        Rock     -> 3
                        Paper    -> 6
                        Scissors -> 0
toScore Paper    y = case y of
                        Rock     -> 0
                        Paper    -> 3
                        Scissors -> 6
toScore Scissors y = case y of
                        Rock     -> 6
                        Paper    -> 0
                        Scissors -> 3

toMove :: String -> Move
toMove [x] | elem x "AX" = Rock
           | elem x "BY" = Paper
           | elem x "CZ" = Scissors
-- part 1
-- main = interact $ show . sum
--                  . map ((\[x, y]->toScore x y + rate y) . map toMove . words)
--                  . lines

doLine :: String -> Int
doLine line = toScore opp (mymove) + rate mymove
    where [oppcom, req] = words line
          opp = toMove oppcom
          mymove = case req of
                "X" -> case opp of
                        Rock     -> Scissors
                        Paper    -> Rock
                        Scissors -> Paper
                "Y" -> opp
                "Z" -> case opp of
                        Rock     -> Paper
                        Paper    -> Scissors
                        Scissors -> Rock
-- part 2
main = interact $ show . sum
                 . map doLine
                 . lines
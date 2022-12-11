module Main where
import Prelude hiding (Right, Left)
main = interact solution1

unique :: Eq a => [a] -> [a]
unique [] = []
unique (x:xs) = x: (unique . filter (/=x)) xs

data Diff = Diff Int Int deriving (Show, Eq)
instance Num Diff where
  (Diff x1 y1) + (Diff x2 y2) = Diff (x1 + x2) (y1 + y2)
  (Diff x1 y1) - (Diff x2 y2) = Diff (x1 - x2) (y1 - y2)
  (Diff x1 y1) * (Diff x2 y2) = Diff (x1 * x2) (y1 * y2)
  abs (Diff x y) = Diff (abs x) (abs y)
  signum (Diff x y) = Diff (signum x) (signum y)
  fromInteger = flip Diff 0 . fromInteger

parseDir :: String -> [Diff]
parseDir (d:xs) = let n = read . tail $ xs
                      d' = case d of {'U'->Diff 0 1;'D'->Diff 0 (-1);
                                      'L'->Diff (-1) 0;'R'->Diff 1 0}
                    in take n (repeat d')

-- (Head, Tail)
gmov p d = let sd = signum d
               ad = abs d
             in case ad of {
                 (Diff 1 2) -> Diff 1 1;
                 (Diff 2 1) -> Diff 1 1;
                 (Diff 2 0) -> Diff 1 0;
                 (Diff 0 2) -> Diff 0 1;
                 _          -> Diff 0 0;
             } * sd
step :: (Diff, Diff) -> Diff -> (Diff, Diff)
step (h, t) d = let h' = h + d in (h', t + gmov t (h' - t))

parse :: String -> [Diff]
parse = foldl1 (++) . map parseDir . lines

solution1 = show . length . unique
          . map snd . scanl step (Diff 0 0, Diff 0 0) . parse

type Rope = [Diff] -- (Head, Tail)

mlanu :: Diff -> Diff -> Diff
mlanu h t = t + gmov h (h - t)
move :: Rope -> Diff -> Rope
move r d = let r' = (head r + d: tail r) in scanl1 mlanu r'

solution2 = show . length . unique . foldr (++) []
          . scanl move (take 2 . repeat $ Diff 0 0) . parse
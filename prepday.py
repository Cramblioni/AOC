import sys, os
if __name__ == "__main__":
    # arg[1] -> year
    # arg[2] -> day
    [_, year, day, *_] = sys.argv
    basepath = os.path.abspath(f"./{year}/day{day}")+"/"
    if not os.path.exists(year):
        os.mkdir(year)
    if os.path.exists(basepath):
        print("Directory already exists", file=sys.stderr)
    os.mkdir(basepath)
    with open(basepath+"build.bat", "w") as f: f.write("ghc -o solution.exe solution.hs -no-keep-o-files -no-keep-hi-files")
    with open(basepath+"build.sh", "w") as f: f.write("ghc -o solution solution.hs -no-keep-o-files -no-keep-hi-files")
    with open(basepath+"test.txt", "w") as f: f.write("")
    with open(basepath+"input.txt", "w") as f: f.write("")
    with open(basepath+"solution.hs", "w") as f: f.write("module Main where\nmain = interact solution1\nsolution1 = const \"yeet\"")
    
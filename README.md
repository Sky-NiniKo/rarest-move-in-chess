This is a lil' code to analyze chess .pgn files, with the goal of finding the "rarest" move in chess.

That is, the rarest move notation (standard algebraic notation) given a large number of input games (e.g. every rated game from lichess) in pgn format.

However, since there are many moves that never happen, this is moreso counting and categorizing moves of various types rather than finding one specific rare move.

[See the video about this data here](https://youtu.be/iDnW0WiCqNc)

## Running

This was written using zig 0.14.1.

This analysis is done in 2 separate phases (and hence programs)

1. Read pgn data from stdin, count moves, store in a move string => int mapping, save data to a temporary .result.json file
   - We also save games that contain rare moves to use as examples
   - We also save some statistics like total games processed and total bytes processed
2. Read multiple .result.json files, merge into one map of move => count. Perform analysis on these moves.

- Phase 1 can be run with `zig build run -- collect < games.pgn > result.json` or `zstdcat ./compressed/lichess_20XX-YY.pgn.zst | zig build run -- collect > result.json` if using compressed data from lichess.
  - Note: you should use `-Doptimize=ReleaseFast` here since this is a slow process for recent months of data.
  - This parses ~100k games / sec on my machine, but running multiple instances of this script allows processing multiple months in parallel. I could get ~400k games / sec this way. Recent months from Lichess are ~30GB compressed, which takes ~15 min to process at 100k games / sec.
- Phase 2 can be run with `zig build run -- analyze partialResults/`.
  - This loads all `.result.json` games in the `partialResults/` folder, and prints analysis out to stdout.

## About

Note that pgn files used in my analysis are not included in this repo, because I used 1500 Gigabytes of them.
This repo _does_ include the counts of encountered moves from the pgn files I analyzed (the .result.json files from the _collect_ phase).

The interesting stuff happens in the analyze phase.
It counts how many moves are of different forms, like promotions, disambiguations, etc.
We also look for the percent "coverage" we get, by comparing how many moves of different pieces we see compared to how many we could theoretically see.
See src/analyze.zig for the logic that counts how many possible moves there are.

There's also a couple of scripts here to help compute how many possible moves there are using a python chess library. (this is used to find the % coverage)

Why is this written in zig? Just for funzies

## Results

_**Update**: This repo now contains additional data from 2024. The analysis shown in this README does not include this updated data.
Use `zig build run -- analyze partialResults/` to see the analysis with updated data.
This includes people achieving the "rarest move"._

I analyzed all of the [rated game data from lichess](https://database.lichess.org/#standard_games) between July 2014 and December 2023.

This analysis included **342,490,585,837 moves** from **5,163,425,477 games**, from **9.4TB** of uncompressed pgn game data.

Note that before July 2014, there seems to be some bug in the Lichess game data that reports some moves
not in their most simple form, for example,
there are some doubly disambiguated rook moves (this is never necessary)
and some doubly disambiguated knight moves that could be expressed as rank or file disambiguations.
Hence data before July 2014 is excluded. It's a measely 8,247,741 games, or 0.1% of total games excluded.

I also looked at a few more smaller datasets but they're so few games I excluded them from the analysis.

Some categories of rare moves are:

- Doubly Disambiguated Queen capture checkmates, like Qc3xd4#
- Rank-Disambiguated Bishop capture checkmates, like B3xd4#
- Doubly Disambiguated Knight _Non-Capture_ Checkmates like Na1b3# (So far exactly 1 example of this)
- Doubly Disambiguated Knight Capture Checkmates like Na1xb3# (I've never seen an example of this)
- Doubly Disambiguated Bishop Capture Checkmates like Bb3xc4# (I've never seen an example of this)

Each of these has less-rare variants like non-capture mates, capture with check, etc.

Much of the rarity and interesting cases come from disambiguations inherent to standard algebraic notation,
but you could argue this is purely a property of the notation, and not really related to chess.
If you prefer not including disambiguations, see simplified_results.json which strips out check, checkmate and disambiguations
to give an ordered list of moves. According to that method, the rarest move is `fxg1=B`.
I enjoy the additional complication of the notational rarity, which is what the bulk of this analysis focuses on.

Running the analysis with the included partialResults gives this output:

```
Reading data from lichess_db_standard_rated_2020-08.result.json
  > Games:     71,131,606  Moves:  4,760,057,166      Bytes: 0.2TB, BytesFromGames: 0.1TB      unique moves: 16,415, interesting games: 1
Reading data from lichess_db_standard_rated_2021-11.result.json
  > Games:     86,886,214  Moves:  5,762,124,818      Bytes: 0.2TB, BytesFromGames: 0.2TB      unique moves: 16,654, interesting games: 7

...

Reading data from lichess_db_standard_rated_2018-07.result.json
  > Games:     21,027,590  Moves:  1,411,274,965      Bytes: 44.8GB, BytesFromGames: 37.0GB      unique moves: 15,152, interesting games: 0
Reading data from lichess_db_standard_rated_2025-05.result.json
  > Games:     93,893,357  Moves:  6,250,217,326      Bytes: 0.2TB, BytesFromGames: 0.2TB      unique moves: 16,636, interesting games: 2

wrote combined result data to results.json
wrote simplified result data to simplified_results.json

Total Moves:     447,975,801,885
Unique Moves:             21,761
Total Games:       6,746,386,047
Data processed (uncompressed): 15.0TB
Data processed (uncompressed, excluding annotations): 12.5TB


Total moves:    447,975,801,885           -  21,761 unique (73.14% coverage)

♟ Pawn moves:   125,013,061,889 (27.91%)  -     924 unique (100.00% coverage)
♚ King moves:    48,278,775,887 (10.78%)  -     382 unique (99.48% coverage)
♜ Rook moves:    62,851,344,542 (14.03%)  -   5,296 unique (96.78% coverage)
♞ Knight moves:  78,106,636,699 (17.44%)  -   2,946 unique (73.07% coverage)
♛ Queen moves:   55,082,004,400 (12.30%)  -   9,419 unique (68.37% coverage)
♝ Bishop moves:  68,296,405,479 (15.25%)  -   2,788 unique (54.03% coverage)

         23.83% of all moves are captures
          7.09% of all moves are checks
          0.39% of all moves are checkmates
          2.44% of all moves are capture checks
          0.13% of all moves are capture checkmates

  1,167,983,860 promotions (0.26% of moves)
  1,141,261,455 ♛ Queen promotions  (97.71% of promotions)
     16,140,748 ♜ Rook promotions   (1.38% of promotions)
      7,313,072 ♞ Knight promotions (0.63% of promotions)
      3,268,585 ♝ Bishop promotions (0.28% of promotions)

  8,698,521,745 O-O    moves
  1,612,669,978 O-O-O  moves
      2,690,462 O-O+   moves
     33,625,017 O-O-O+ moves
         21,730 O-O#   moves
         44,057 O-O-O# moves

     60,856,143 ♟ Pawn mates (0.0135847%)
        858,627 potential en passant pawn mates (0.0001917%)
         21,730 short castle mates (0.0000049%)
         44,057 long castle mates (0.0000098%)

  1,137,261,953 ♛ Queen mates   (0.25387% of all moves) (64.82% of mates)
    444,895,594 ♜ Rook mates    (0.09931% of all moves) (25.36% of mates)
     60,856,143 ♟ Pawn mates    (0.01358% of all moves) (3.47% of mates)
     56,418,635 ♝ Bishop mates  (0.01259% of all moves) (3.22% of mates)
     54,523,104 ♞ Knight mates  (0.01217% of all moves) (3.11% of mates)
        457,029 ♚ King mates    (0.00010% of all moves) (0.03% of mates)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♛ Queen ♛ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 55,082,004,400 Queen total (12.295754406%)
 17,799,789,576 Queen total captures (3.973381933%)
 11,327,571,728 Queen total checks (2.528612412%)
  1,137,261,953 Queen total mates (0.253866827%)
  3,532,316,646 Queen total capture checks (0.788506127%)
    427,088,110 Queen total capture mates (0.095337317%)

    215,909,349 Queen file disambiguations (0.048196654%)
     15,571,759 Queen file disambiguations captures (0.003476027%)
    104,763,476 Queen file disambiguations checks (0.023385968%)
     49,826,653 Queen file disambiguations mates (0.011122622%)
      7,172,569 Queen file disambiguations capture checks (0.001601106%)
      3,825,707 Queen file disambiguations capture mates (0.000853999%)

     20,413,263 Queen rank disambiguations (0.004556778%)
      2,238,234 Queen rank disambiguations captures (0.000499633%)
      9,792,213 Queen rank disambiguations checks (0.002185880%)
      3,642,606 Queen rank disambiguations mates (0.000813126%)
      1,061,299 Queen rank disambiguations capture checks (0.000236910%)
        518,935 Queen rank disambiguations capture mates (0.000115840%)

         82,061 Queen double disambiguations (0.000018318%)
            743 Queen double disambiguations captures (0.000000166%)
         17,948 Queen double disambiguations checks (0.000004006%)
         13,599 Queen double disambiguations mates (0.000003036%)
            252 Queen double disambiguations capture checks (0.000000056%)
            223 Queen double disambiguations capture mates (0.000000050%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♝ Bishop ♝ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 68,296,405,479 Bishop total (15.245556834%)
 19,683,759,465 Bishop total captures (4.393933642%)
  4,430,141,465 Bishop total checks (0.988924278%)
     56,418,635 Bishop total mates (0.012594126%)
  2,044,388,000 Bishop total capture checks (0.456361257%)
     15,539,155 Bishop total capture mates (0.003468749%)

        246,933 Bishop file disambiguations (0.000055122%)
          6,422 Bishop file disambiguations captures (0.000001434%)
         39,993 Bishop file disambiguations checks (0.000008927%)
          5,593 Bishop file disambiguations mates (0.000001249%)
            869 Bishop file disambiguations capture checks (0.000000194%)
            141 Bishop file disambiguations capture mates (0.000000031%)

         28,967 Bishop rank disambiguations (0.000006466%)
            771 Bishop rank disambiguations captures (0.000000172%)
            490 Bishop rank disambiguations checks (0.000000109%)
             98 Bishop rank disambiguations mates (0.000000022%)
            149 Bishop rank disambiguations capture checks (0.000000033%)
             36 Bishop rank disambiguations capture mates (0.000000008%)

            887 Bishop double disambiguations (0.000000198%)
              7 Bishop double disambiguations captures (0.000000002%)
              7 Bishop double disambiguations checks (0.000000002%)
             10 Bishop double disambiguations mates (0.000000002%)
              0 Bishop double disambiguations capture checks (0.000000000%)
              5 Bishop double disambiguations capture mates (0.000000001%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♞ Knight ♞ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 78,106,636,699 Knight total (17.435458873%)
 18,241,910,886 Knight total captures (4.072075056%)
  4,761,067,279 Knight total checks (1.062795637%)
     54,523,104 Knight total mates (0.012170993%)
  1,776,887,918 Knight total capture checks (0.396648192%)
     10,328,967 Knight total capture mates (0.002305698%)

  4,272,177,795 Knight file disambiguations (0.953662626%)
    398,293,043 Knight file disambiguations captures (0.088909499%)
     50,215,374 Knight file disambiguations checks (0.011209394%)
        609,931 Knight file disambiguations mates (0.000136153%)
     11,137,500 Knight file disambiguations capture checks (0.002486183%)
         66,457 Knight file disambiguations capture mates (0.000014835%)

    205,389,389 Knight rank disambiguations (0.045848322%)
     15,075,583 Knight rank disambiguations captures (0.003365267%)
      5,361,652 Knight rank disambiguations checks (0.001196862%)
         86,415 Knight rank disambiguations mates (0.000019290%)
        742,118 Knight rank disambiguations capture checks (0.000165660%)
          7,327 Knight rank disambiguations capture mates (0.000001636%)

          2,582 Knight double disambiguations (0.000000576%)
              9 Knight double disambiguations captures (0.000000002%)
            732 Knight double disambiguations checks (0.000000163%)
             66 Knight double disambiguations mates (0.000000015%)
              1 Knight double disambiguations capture checks (0.000000000%)
              6 Knight double disambiguations capture mates (0.000000001%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♜ Rook ♜ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 62,851,344,542 Rook total (14.030075794%)
 17,210,396,158 Rook total captures (3.841813796%)
  8,945,892,421 Rook total checks (1.996958850%)
    444,895,594 Rook total mates (0.099312416%)
  2,769,090,479 Rook total capture checks (0.618133941%)
    109,285,077 Rook total capture mates (0.024395308%)

  9,187,680,591 Rook file disambiguations (2.050932339%)
    395,492,746 Rook file disambiguations captures (0.088284399%)
    246,131,900 Rook file disambiguations checks (0.054943124%)
     15,498,268 Rook file disambiguations mates (0.003459622%)
     37,577,952 Rook file disambiguations capture checks (0.008388389%)
      3,822,271 Rook file disambiguations capture mates (0.000853232%)

    503,615,126 Rook rank disambiguations (0.112420163%)
     48,869,632 Rook rank disambiguations captures (0.010908989%)
     81,866,703 Rook rank disambiguations checks (0.018274805%)
      8,888,844 Rook rank disambiguations mates (0.001984224%)
      3,353,563 Rook rank disambiguations capture checks (0.000748604%)
        118,157 Rook rank disambiguations capture mates (0.000026376%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♚ King ♚ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 48,278,775,887 King total (10.777094585%)
  5,421,386,513 King total captures (1.210196285%)
     36,407,259 King total checks (0.008127059%)
        457,029 King total mates (0.000102021%)
      2,593,185 King total capture checks (0.000578867%)
         17,656 King total capture mates (0.000003941%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♟ Pawn ♟ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
125,013,061,889 Pawn total (27.906208631%)
 28,386,745,100 Pawn total captures (6.336669298%)
  2,242,830,718 Pawn total checks (0.500658899%)
     60,856,143 Pawn total mates (0.013584694%)
    785,816,491 Pawn total capture checks (0.175414942%)
      7,129,538 Pawn total capture mates (0.001591501%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♟ → * Promotion ♟ → * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1,167,983,860 Promotion total (0.260724766%)
     73,609,603 Promotion total captures (0.016431602%)
    319,543,694 Promotion total checks (0.071330570%)
     32,687,262 Promotion total mates (0.007296658%)
     40,370,390 Promotion total capture checks (0.009011735%)
      3,815,572 Promotion total capture mates (0.000851736%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♟ → ♛ Promotion to Queen ♟ → ♛ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1,141,261,455 Promotion to Queen total (0.254759621%)
     71,364,352 Promotion to Queen total captures (0.015930403%)
    313,307,607 Promotion to Queen total checks (0.069938511%)
     30,126,245 Promotion to Queen total mates (0.006724971%)
     39,197,400 Promotion to Queen total capture checks (0.008749892%)
      3,628,652 Promotion to Queen total capture mates (0.000810011%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♟ → ♛ Promotion to Bishop ♟ → ♛ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      3,268,585 Promotion to Bishop total (0.000729634%)
        250,110 Promotion to Bishop total captures (0.000055831%)
      1,000,899 Promotion to Bishop total checks (0.000223427%)
         33,116 Promotion to Bishop total mates (0.000007392%)
         47,972 Promotion to Bishop total capture checks (0.000010709%)
            820 Promotion to Bishop total capture mates (0.000000183%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♟ → ♛ Promotion to Knight ♟ → ♛ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      7,313,072 Promotion to Knight total (0.001632470%)
        832,250 Promotion to Knight total captures (0.000185780%)
      2,694,839 Promotion to Knight total checks (0.000601559%)
         40,906 Promotion to Knight total mates (0.000009131%)
        463,291 Promotion to Knight total capture checks (0.000103419%)
          4,526 Promotion to Knight total capture mates (0.000001010%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ♟ → ♛ Promotion to Rook ♟ → ♛ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     16,140,748 Promotion to Rook total (0.003603040%)
      1,162,891 Promotion to Rook total captures (0.000259588%)
      2,540,349 Promotion to Rook total checks (0.000567073%)
      2,486,995 Promotion to Rook total mates (0.000555163%)
        661,727 Promotion to Rook total capture checks (0.000147715%)
        181,574 Promotion to Rook total capture mates (0.000040532%)
```

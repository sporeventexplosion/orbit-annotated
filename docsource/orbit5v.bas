'# This is my (n+1)th attempt at annotating the Orbit5V source code. Hopefully
'# have slightly better luck this time.
'#
'# Most original code is retained in this annotated version, besides the
'# following:
'# - modifications to whitespace to clarify code indentation. All indentation
'#   (most original indentation is 1 space) has been converted to 4 spaces.
'# - All keywords and commands have been converted to uppercase.
'# - Some commented lines and unreferenced labels have been removed.
'# Note that uncommented unreachable code and code without any effect is kept
'# and is labeled as such.

'# `GOTO 9000` when an error occurs, most likely when opening `starsr`.
1111    ON ERROR GOTO 9000

'# Prepare graphics mode: mode 12 is 640x480 pixels, 256k colors to 16
'# attributes, and a char size of 8x16 or 8x8.
'#
'# Palette 8 is set to `#4c4c4c` (dark gray) and palette 15 to `#a8a8a8`
'# (light gray) in hex.
        SCREEN 12
        PALETTE 8, 19 + (19 * 256) + (19 * 65536)
        PALETTE 15, 42 + (42 * 256) + (42 * 65536)

'# Make variables/arrays starting with a character from A to Z doubles by
'# default.
        DEFDBL A-Z

'# Define a number of arrays for storing various information. Note that in BASIC
'# an array `A(10)` has 11 elements.
'#
'# `Pz` is an array of "singles" and `Znme$` is an array of strings,
'# while all other are of "doubles".
'#
'# - `P` possibly stands for "properties". Contains various properties of each
'#   object (body).
'#    - `P(i, 0)` is the draw color code of object `i`.
'#    - `P(i, 1)` and `P(i, 2)` hold the "cumulative net" x and y acceleration
'#      of object `i` in `m/s^2`. Used in the calculating change in velocity
'#      of an object during each "step" of the simulation.
'#    - `P(i, 4)` is the mass of object `i` in kg.
'#    - `P(i, 5)` is the radius of object `i` in m.
'# - `Px` and `Py` each contains values related to the position of each object
'#   (TODO: clarify). It appears that `Px(i, 3)` and `Py(i, 3)` contain the x
'#   and y positions of object `i` respectively in meters.
'# - `Vx` and `Vy` respectively contain the x and y velocities of each object.
'#   `Vx(i)` and `Vy(i)` contain the x and y velocities of object `i`
'#   respectively in `m/s`.
'# - `B` is an array of object pairs, the first of which in each pair applies a
'#   gravitational force on the second. The first index denotes whether the
'#   object is the first or second object in a pair, and the second index
'#   denotes the pair number. Each value is an object "ID".
'# - `Znme$` is an array of strings. The first 40 (index `0-39`) are names of
'#   objects as read from `starsr` and the values of index 40, 41, 42,
'#   hard-coded below, are respectively "TARGET", "Vtg", "Pch".
'# - `panel` contains data for drawing the panel borders using box-drawing
'#   characters in the main user interface. `panel(0, i)`, `panel(1, i)`, and
'#   `panel(2, i)` each corresponds to the x coordinate, y coordinate, and
'#   code page 437 character code in decimal for each box-drawing character.
'#   Has have other uses (TODO: explain other uses).
'#
'# TODO: Determine the purposes of the all of the following arrays
        DIM P(40, 11), Px(40, 3), Py(40, 3), Vx(40), Vy(40), B(1, 250), Ztel(33), Znme$(42), panel(2, 265), TSflagVECTOR(20)
        DIM Pz(3021, 2) AS SINGLE

'# Open `starsr` in "read-only" mode with filenumber #1.
91      OPEN "I", #1, "starsr"

'# Read the first 3021 lines of `starsr` into `Pz`, beginning with index 1 of
'# `Pz`. Each of the 3021 lines contains 3 numbers. This corresponds to lines
'# `1-3021` (1-based).
        FOR i = 1 TO 3021
            INPUT #1, Pz(i, 0)
            INPUT #1, Pz(i, 1)
            INPUT #1, Pz(i, 2)
        NEXT i

'# Read the next 241 lines of `starsr` into `B`, beginning with index 1 of
'# `B`. Each of the 241 lines contains 2 numbers. This corresponds to lines
'# `3022-3262`.
        FOR i = 1 TO 241
            INPUT #1, B(0, i)
            INPUT #1, B(1, i)
        NEXT i

'# Read the next 40 lines of `starsr` into `P`, beginning with index 0 of
'# `P`. Each of the 40 lines contains 6 numbers. This corresponds to lines
'# `3263-3302`.
        FOR i = 0 TO 39
            INPUT #1, P(i, 0)
            INPUT #1, P(i, 4)
            INPUT #1, P(i, 5)
            INPUT #1, P(i, 8)
            INPUT #1, P(i, 9)
            INPUT #1, P(i, 10)
        NEXT i

'# Read the next line of `starsr` into `year`, `day`, `hr`, `min`, `sec`. This
'# line appears to be a timestamp. This corresponds to line `3303`.
        INPUT #1, year, day, hr, min, sec

'# Read the next 36 lines of `starsr` into different parts of `Px`, `Py`, `Vx`,
'# `Vy`, and `P`, beginning with index 0 of each of the above arrays. Each of
'# the 36 lines contains 6 numbers. This corresponds to lines `3304-3339`.
        FOR i = 0 TO 35
            INPUT #1, Px(i, 3), Py(i, 3), Vx(i), Vy(i), P(i, 1), P(i, 2)
        NEXT i

'# Read the next 40 lines of `starsr` into `Znme$`, beginning with index 0 of
'# `Pz`. Each of the 40 lines contains 1 string containing the name of an
'# object. This corresponds to lines `3340-3379`
        FOR i = 0 TO 39
            INPUT #1, Znme$(i)
        NEXT i

'# Read the next 265 lines of `starsr` into `panel`, beginning with second
'# index 1 of `panel`. The value of the `i` is the first index and the value
'# of the `j` is the second index. Each of the 265 lines contains 3 numbers.
'# This corresponds to lines `3380-3644`.
        FOR i = 1 TO 265
            FOR j = 0 TO 2
                INPUT #1, panel(j, i)
            NEXT j
        NEXT i

'# Set a few hard-coded strings in `Znme$`.
        Znme$(40) = "TARGET"
        Znme$(42) = " Vtg"
        Znme$(41) = " Pch"

'# TODO: what is the following for?
        Px(37, 3) = 4446370.8284487# + Px(3, 3): Py(37, 3) = 4446370.8284487# + Py(3, 3): Vx(37) = Vx(3): Vy(37) = Vy(3)

'# Close `starsr`.
        CLOSE #1
'# Open `marsTOPOLG.RND` in "random" mode with filenumber #3 and record
'# length 2.
        open "R", #3, "marsTOPOLG.RND",2

'# The radius of "Hyperion", stored in a separate variable.

        PH5 = P(12, 5)

'# Set a number of constants.

'# `ENGsetFLAG` indicates whether the engine is on (1) or not on (0). The
'# default value, set below, is `1`, or "on". TODO: confirm
        ENGsetFLAG = 1

'# `mag` controls the magnification factor of the main display. Its effective
'# unit can be understood to be pixels/AU. It is the length in pixels
'# of a 1 astronomical unit line. The default value, set below, is `25`, for
'# 25 pixels per AU.
        mag = 25

'# `ref` is the ID of the object currently used as the "reference" object.
        ref = 3
        trail = 1
        ts = .25
        fuel = 2000
        AYSEfuel = 15120000

'# Set a number of physical, mathematical, and astronomical constants:
'# - `AU`:, the number of meters in 1 astronomical unit
'# - `RAD`:, the number of degrees in 1 radian
'# - `G`:, the gravitational constant in `m^3*kg^-1*s^-2`
'# - `pi`: and `pi2` are pi and 2 * pi respectively.
        AU = 149597890000#
        RAD = 57.295779515#
        G = 6.673E-11
        pi = 3.14159
        pi2 = 2 * pi

'# Something to do with timesteps. TODO: find exact function of TSFlagVECTOR.
        TSflagVECTOR(1)=0.015625
        TSflagVECTOR(2)=0.03125
        TSflagVECTOR(3)=0.0625
        TSflagVECTOR(4)=0.125
        TSflagVECTOR(5)=0.25
        TSflagVECTOR(6)=0.25
        TSflagVECTOR(7)=0.25
        TSflagVECTOR(8)=0.5
        TSflagVECTOR(9)=1
        TSflagVECTOR(10)=2
        TSflagVECTOR(11)=5
        TSflagVECTOR(12)=10
        TSflagVECTOR(13)=20
        TSflagVECTOR(14)=30
        TSflagVECTOR(15)=40
        TSflagVECTOR(16)=50
        TSflagVECTOR(17)=60

'# The current timestep choice as an index in TSflagVECTOR?
'#
'# TODO: verify the above.
        TSindex=5

'# TODO: what is this?
        OLDts = .25

'# Open `orbitstr.txt` in "read-only" mode with filenumber #1.
'#
'# If the orbitstr file is empty, let `z$=""`, close the file and skip to
'# `51` If it is not empty, read the first word of the first line of the file
'# into z$. If it is "normal", let `z$=""`. Close file #1.
'#
'# Open `orbitstr.txt` in "write" mode with filenumber #1.
'#
'# If the first word of the first line of orbitstr.txt is "RESTART", write
'# "OSBACKUP" to the file. Close file #1. If it is not empty, jump to `52`
'#
'# **Summary**: If `z$` is empty or `"normal"`, proceed to `51`. In all other
'# cases, jump to `52`. If `z$` is `"RESTART"`, overwrite file #1 with
'# `"OSBACKUP"`
        'load situation file
        OPEN "I", #1, "orbitstr.txt"
        IF EOF(1) THEN z$="": CLOSE #1: GOTO 51
        INPUT #1, z$
        IF z$="normal" THEN z$=""
        CLOSE #1
        OPEN "O", #1, "orbitstr.txt"
        IF z$="RESTART" THEN PRINT #1, "OSBACKUP"
        CLOSE #1
        IF z$<>"" THEN 52

'# If `z$` is empty, create input at (5, 5) on the screen (note that
'# coordinates are 1-based) with the prompt `Restart previous state (or type
'# filename)? ` and store input in `y$`.
'#
'# If `q` is entered (case-insensitive), end the program.
'#
'# If `y` (case-insensitive) or the empty string is entered, let
'# `z$="OSBACKUP"` and jump to `52`.
'#
'# **Summary**: Create input. Quit if input is `"q"` (case-insensitive); jump
'# to `52` if input is `"y"` (case-insensitive) or empty.
51      LOCATE 5,5
        IF z$ = "" THEN INPUT ; "Restart previous state (or type filename)? ", y$
        IF UCASE$(LEFT$(y$, 1)) = "Q" THEN END
        IF UCASE$(LEFT$(y$, 1)) = "Y" THEN z$ = "OSBACKUP": GOTO 52
        IF y$ = "" THEN z$ = "OSBACKUP": GOTO 52
        z$=y$

'# The `end` on this line appear to be unreachable.
        IF z$ = "" THEN END

'# Let `filename$ = z$`. Go to sub `701`. After return, go to sub `405`.
52      filename$ = z$: GOSUB 701
        GOSUB 405

'# `TIMER` "returns the amount of time that has passed since a static
'# reference point". Initialize tttt using this value.
        'Initialize frame rate timer
100     tttt = TIMER

'# Set `P(i, 1)` and `P(1, 2)` for p from 1-35 (both inclusive), 38, and 39
'# to 0. TODO: Find why not 36, 37, and 40.
        'Zero acceleration variables
        FOR i = 0 TO 35: P(i, 1) = 0: P(i, 2) = 0: NEXT i
        P(38, 1) = 0
        P(38, 2) = 0
        P(39, 1) = 0
        P(39, 2) = 0

        'Erase target vector
        IF DISPflag = 0 THEN LINE (30, 120)-(30 + (20 * SIN(Atarg)), 120 + (20 * COS(Atarg))), 0
        IF SQR(((Px(28, 3) - cenX) * mag / AU) ^ 2 + ((Py(28, 3) - cenY) * mag * 1 / AU) ^ 2) > 400 THEN 131
        IF vflag = 1 THEN LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (30 * SIN(Atarg)) + (Px(28, 3) - cenX) * mag / AU, 220 + (30 * COS(Atarg)) + (Py(28, 3) - cenY) * mag * 1 / AU), 0
        IF vflag = 1 THEN LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (10 * SIN(Sangle)) + (Px(28, 3) - cenX) * mag / AU, 220 + (10 * COS(Sangle)) + (Py(28, 3) - cenY) * mag * 1 / AU), 0

131     CONflag = 0
        CONtarg = 0
        RcritL = 0
        atm = 40
        LtrA = 0
        explFLAG1 = 0
        COLeventTRIG = 0
        MARSelev=0
        CONflag2=0

'# ## Calculation of acceleration due to gravity
'#
'# The following calculates gravitational acceleration caused by the first
'# object on the second in each object pair in `B`. Note that in each pair,
'# only the first object in the pair causes an acceleration on the second, and
'# not vice versa. There must be a separate pair with swapped first and second
'# objects for the second objects to cause acceleration on the first.
'#
'# `GOTO 106` is used like "continue". `106` is the `NEXT i` statement at the
'# bottom of the loop.
        'Calculate gravitational acceleration for each object pair
        FOR i = 1 TO 241
'# For each of the pairs:
'#
'# TODO: clarify all of the below
'#
'# "continue" if the first and second objects in the pair are the same object.
'#
'# If either `ufo1` or `ufo2` is `0` and one of the objects in the pair has
'# ID 38 or 39, "continue". TODO: determine the use of `ufo1` and `ufo2`.
'#
'# If the second object of the pair is `"AYSE    "` (ID 32) and `AYSE` is 150,
'# "continue."
            IF B(1, i) = B(0, i) THEN 106
            IF ufo1 = 0 AND (B(1, i) = 38 OR B(0, i) = 38) THEN 106
            IF ufo2 = 0 AND (B(1, i) = 39 OR B(0, i) = 39) THEN 106
            IF B(1, i) = 32 AND AYSE = 150 THEN 106

'# Find the difference in x-coordinate and y-coordinate for the pair of
'# of objects and store respectively in `difX` and `difY`.
            difX = Px(B(1, i), 3) - Px(B(0, i), 3)
            difY = Py(B(1, i), 3) - Py(B(0, i), 3)

'# Go to sub `5000`.
'#
'# Calculate the angle from the first object to the second in radians. The
'# result is in the variable `angle`. See sub `5000` for detail.
            GOSUB 5000

'# Calculate the distance between the two objects using the Pythagorean
'# theorem. Clamp the minimum distance to a value of 0.01 m. TODO: confirm
'# units.
            r = SQR((difY ^ 2) + (difX ^ 2))
            IF r < .01 THEN r = .01

'# The magnitude of the acceleration caused to the second object by the first
'# (both assumed to be point masses/spherically symmetric) is `G*m1/r^2` where
'# m1 is the mass of the first object in the pair. `a` contains this value.
            a = G * P(B(0, i), 4) / (r ^ 2)

'# Because `r * SIN(angle) = -difX` and `r * COS(angle) = -difY`,
'# `(a * SIN(angle), a * COS(angle))` represents the acceleration vector of
'# the second object of the pair towards the first.
'#
'# The second level indexes 1 and 2 of P appear to be the "net" acceleration.
'# up to this point in the loop. TODO: confirm
            P(B(1, i), 1) = P(B(1, i), 1) + (a * SIN(angle))
            P(B(1, i), 2) = P(B(1, i), 2) + (a * COS(angle))

'# TODO: find out why these cases of "Hyperion" and "artificial objects"
'# receive special handling.
'#
'# Pairs 79, 136, 195, 230 are respectively "Hyperion" and "Habitat ",
'# "Hyperion" and "AYSE    ", "Hyperion" and "PROBE   ", and "Hyperion" and
'# "unknown "
            IF i = 79 OR i = 136 OR i = 195 OR i = 230 THEN GOSUB 166

'# Pair 67 is "Mars    " and "Habitat ". If the current pair is pair 67 and
'# the distance between the two is less than 3,443,500 m (TODO: confirm units)
'# perform special handling:
'#
'# Set `ELEVangle` to angle, execute sub `8500`, and let `MARSelev=h` and
'# `r=r-h`.
            IF i = 67 AND r<3443500 then ELEVangle=angle: gosub 8500: MARSelev=h:r=r-h

            'IF i = 79 THEN GOSUB 166

'# The following lines perform special handling for "Habitat ", "AYSE    ",
'# and "PROBE   ".
'#
'# If the second element in the pair is not one of the above, jump to `2`
'# below. TODO: complete.
            IF B(1, i) <> 28 AND B(1, i) <> 32 AND B(1, i) <> 38 THEN 2
            IF (SGN(difX) <> -1 * SGN(Vx(B(1, i)) - Vx(B(0, i)))) OR (SGN(difY) <> -1 * SGN(Vy(B(1, i)) - Vy(B(0, i)))) THEN 2
            Vhab = SQR((Vx(B(1, i)) - Vx(B(0, i))) ^ 2 + (Vy(B(1, i)) - Vy(B(0, i))) ^ 2)
            IF r < ts * Vhab THEN ts = (r - (P(B(0, i), 5) / 2)) / Vhab

'# The following performs extra special handling.

'# If the second object in the pair is "AYSE    " and the distance between
'# the (center of) the two objects is less than or equal to the sum of their
'# radii, let `CONflag2=1` and `CONflag3=(the ID of the first object)`.
2           IF B(1, i) = 32 AND r <= P(B(0, i), 5) + P(32, 5) THEN CONflag2 = 1: CONflag3 = B(0, i)': targ = 32

'# If the second object in the pair is "Habitat " and (TODO: fully understand)
            IF B(1, i) = 28 AND P(B(0, i), 10) > -150 AND r <= P(B(0, i), 5) + P(28, 5) THEN CONflag = 1: CONtarg = B(0, i): Dcon = r: Acon = angle: CONacc = a

'# If the second object in the pair is "Habitat " and the first object in the
'# pair is not "AYSE    " and ...
'# Something to do with atmospheric simulation (TODO: fully understand)
            IF B(1, i) = 28 AND B(0, i) <> 32 AND r <= P(B(0, i), 5) + (1000 * P(B(0, i), 10)) THEN atm = B(0, i): Ratm = (r - P(B(0, i), 5)) / 1000

'# If the second object in the pair is "unknown " and the distance from the
'# center of each is less than or equal to the sum of their radii (implying
'# a collision of both objects are circular), set `explCENTER` (likely
'# standing for "explosion center") to 39 (the ID of "unknown ") and go to sub
'# `6000`.
            IF B(1, i) = 39 AND r <= P(B(0, i), 5) + P(39, 5) THEN explCENTER = 39: GOSUB 6000
'# If the second object in the pair is "PROBE   " and the distance from the
'# center of each is less than or equal to the sum of their radii, set
'# `explCENTER` to 38 (the ID of "PROBE   ") and go to sub `6000`.
            IF B(1, i) = 38 AND r <= P(B(0, i), 5) + P(38, 5) THEN explCENTER = 38: GOSUB 6000

'# If the pair is "Ganymede" first and "AYSE    " second and the distance from center of
'# "AYSE    " and the center of "Ganymede" is less than the radius of
'# "Ganymede" plus 1,000,000 m, (equivalently, "AYSE    " is less than
'# 1,000,000 m from the surface of "Ganymede" (assumed to be a perfect circle,
'# change the x position and y position of "Ganymede" to both be 1e30.
'# Todo: understand why this exists
            IF (B(1, i) = 32 and B(0, i) = 15) AND r<1000000+P(15,5) THEN Px(15,3)=1e30: Py(15,3)= 1e30

'# Get the angle and distance to the center of the target, relative to
'# "Habitat", and the magnitude of the acceleration cause by the target on
'# "Habitat". Store in the variables `Atarg`, `Dtarg`, and `Acctarg`
'# respectively. Do the above if the first object in the pair is the target
'# object and the second is "Habitat ". The values have already been computed
'# above.
5           IF B(0, i) = targ AND B(1, i) = 28 THEN Atarg = angle: Dtarg = r: Acctarg = a

'# Calculate the theoretical speed of a circular orbit around the reference
'# object relative to the reference object for the habitat at the current
'# distance from the object's center. This only considers the gravitational
'# force of the the reference object and not other objects. This value is
'# stored in `Vref`. The angle and distance to the center of the reference
'# objects are stored in `Aref` and `Dref` respectively using the values
'# computed above.
6           IF B(0, i) = ref AND B(1, i) = 28 THEN Vref = SQR(G * P(B(0, i), 4) / r): Aref = angle: Dref = r

'# Get the angle to Ltr as calculated above (TODO: find what is Ltr) if the
'# first object in the pair is Ltr and store it in the variable `LtrA`.
            IF B(0, i) = Ltr THEN LtrA = a

'# Pair 163 is "AYSE    " and "Habitat ". `AYSEdist` is the distance between
'# "AYSE    " and "Habitat " in m. Store the distance between the center of
'# the two in `AYSEdist`.
'#
'# Pair 166 is "OCESS   " and "Habitat ". `OCESSdist` is the distance between
'# "OCESS   " and "Habitat " in m. Store the distance between the center of
'# the two in `OCESSdist`.
            IF i = 163 THEN AYSEdist = r
            IF i = 166 THEN OCESSdist = r
106     NEXT i
'# ## End of calculation of acceleration due to gravity

'# If the center of "AYSE    " is more than 320 m from the center of
'# "Habitat ", let `AYSE=0`. (TODO: find out what `AYSE` is)
        IF AYSEdist > 320 THEN AYSE = 0

'# (TODO: find the meaning of the below)
        IF CONflag = 1 AND CONtarg = 12 THEN CONflag = .25
        'IF CONflag = 1 AND CONtarg = 14 THEN 9111

'# Record the old (before position update for each step) position of the center
'# of the center object in `cenX` and `cenY`.
'# TODO: find what cenXoff and cenYoff do.
        'Record old center position
101     cenX = Px(cen, 3) + cenXoff
        cenY = Py(cen, 3) + cenYoff

        'Erase velocity, approach velocity, and orientation vectors
        IF DISPflag = 0 THEN LINE (30, 120)-(30 + (5 * SIN(Sangle)), 120 + (5 * COS(Sangle))), 0
        IF DISPflag = 0 THEN LINE (30, 120)-(30 + (10 * SIN(Vvangle)), 120 + (10 * COS(Vvangle))), 0
        IF SQR(((Px(28, 3) - cenX) * mag / AU) ^ 2 + ((Py(28, 3) - cenY) * mag * 1 / AU) ^ 2) > 400 THEN 132
        IF vflag = 1 THEN LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (20 * SIN(Vvangle)) + (Px(28, 3) - cenX) * mag / AU, 220 + (20 * COS(Vvangle)) + (Py(28, 3) - cenY) * mag * 1 / AU), 0

'# Update the velocity of each object based on the acceleration calculated
'# above. "overwrite" the previous object by drawing a black version of itself
'# on its old position.
'#
'# Iterate every object from 37 (or different depending on `ufo1` and `ufo2`,
'# TODO: clarify) to 0 in descending order.
'#
'# `GOTO 108` is used like "continue". `108` is the `NEXT i` statement at the
'# bottom of the loop.
        'Update object velocities and erase old positions
132     FOR i = 37 + ufo1 + ufo2 TO 0 STEP -1

'# Special handling for "Habitat " and "PROBE   ". If the current object is
'# "Habitat ", go to sub `301`. If it is "PROBE   ", go to sub `7200`.
            IF i = 28 THEN GOSUB 301
            IF i = 38 THEN GOSUB 7200

'# Update velocity by adding to the original velocity the acceleration times
'# the old timestep (TODO: find out why old timestep). If the new value is
'# greater than 299999999.999 m/s (incidentally close to the speed of light),
'# the velocity is not updated by skipping the parts that update the velocity
'# to the new value.
            VxDEL = Vx(i) + (P(i, 1) * OLDts)
            VyDEL = Vy(i) + (P(i, 2) * OLDts)
            IF SQR(VxDEL ^ 2 + VyDEL ^ 2) > 299999999.999# THEN 117
            Vx(i) = VxDEL
            Vy(i) = VyDEL

'# "Continue" if the current object is "Module  " and `MODULEflag` is 0.
117         IF i = 36 AND MODULEflag = 0 THEN 108

'# Special handling for "Mars    ". This means that "Mars    " is drawn
'# regardless of how far "out of frame" it is.
            IF i=4 then 11811

'# If the distance of the center of the object to the display center in pixels
'# (taking into account the magnification setting) minus the radius of the
'# object in pixels is greater than 400 (pixels), "continue" (do not draw the
'# object). This prevents the drawing of some objects that cannot be seen on
'# the display.
            IF SQR(((Px(i, 3) - cenX) * mag / AU) ^ 2 + ((Py(i, 3) - cenY) * mag * 1 / AU) ^ 2) - (P(i, 5) * mag / AU) > 400 THEN 108

'# The condition of the following if statement is only true if `cen` and `tr`
'# are both positive (this appears to be the only possible situation). This
'# would imply that `tr` is 1 ("enabled") and the center object is not
'# "Sun     ". For unknown reasons, "continue" if this is the case.
'# TODO: clarify.
11811       IF cen * tr > 0 THEN 108

'# The center of the display for drawing purposes is located at (300, 220),
'# not the geometric center of the display (320, 240).
'#
'# After velocity update but before position update, draw a circle in black
'# (color 0) (to cover old circle drawn in the previous frame, TODO: confirm)
'# if `trail` is 0, or dark gray (color 8) to leave a "trail" at the object's
'# previous position. **INCORRECT** TODO: fix
            IF mag * P(i, 5) / AU < 1.1 THEN CIRCLE (300 + (Px(i, 3) - cenX) * mag / AU, 220 + (Py(i, 3) - cenY) * mag / AU), 1, 8 * trail: GOTO 108
'# Set `clr` (most likely standing for "color", TODO: confirm) to 8 if `trail`
'# is 1, and 0 if `trail` is 0.
            clr = 8 * trail

'# `vnSa` is the angle of the habitat in radians, according to the
'# convention of sub `5000`. Go to sub `128` to either "blank" the drawing of
'# "Habitat " using black or to leave a "trail" using dark gray, depending on
'# `trail`. "Continue" afterwards. The same process is done for "ISS     ",
'# "OCESS   ", and "AYSE    ". These each have their custom draw procedure.
            IF i = 28 THEN vnSa = oldSa: GOSUB 128: GOTO 108
            IF i = 35 THEN GOSUB 138: GOTO 108
            IF i = 37 THEN GOSUB 148: GOTO 108
            IF i = 32 THEN clrMASK = 0: GOSUB 158: GOTO 108
            IF i = 12 AND HPdisp = 1 THEN 108

'# Jump to `118` to perform special drawing if the radius of the current object
'# in pixels is greater than 300.
            IF P(i,5)*mag/AU>300 THEN 118

'# If no special handling is needed, draw a circle with color black or dark gray
'# depending on `trail` to "cover" the old circle or to leave a "trail".
'#
'# `(Px(i, 3) - cenX) * mag / AU` and `(Py(i, 3) - cenY) * mag * 1 / AU)` are
'# respectively the x and y positions of the current object relative to the
'# current center, converted into pixels with regard to the current
'# magnification level. These screen coordinates are offset so that the center
'# corresponds to the screen position (300, 220). `mag * P(i, 5) / AU` is the
'# radius of the current object, converted into pixels. "Continue" after
'# drawing this circle.
            CIRCLE (300 + (Px(i, 3) - cenX) * mag / AU, 220 + (Py(i, 3) - cenY) * mag * 1 / AU), mag * P(i, 5) / AU, 8 * trail: GOTO 108

'# `difX` and `difY` represent the distance from the display center to the
'# center of the current object, in m.
118         difX = cenX-Px(i, 3)
            difY = cenY-Py(i, 3)

'# `dist` is the distance of the center of the object to the display center in
'# pixels minus the radius of the object in pixels. For a circular object, this
'# is effectively the distance from the display center to the surface of the
'# object in pixels. This value is negative when the distance from the display
'# center to the center of the current object is less than the object's radius.

            dist = (SQR((difY ^ 2) + (difX ^ 2)) - P(i, 5)) * mag / AU

'# Go to sub `5000` to calculate the angle from the current object to the
'# display center (see sub `5000` for angle convention).
            GOSUB 5000

'# Convert `angle` from radians to degrees and multiply the result by 160,
'# round to the nearest integer, divide by 160, and then convert back to radians.
'#
'# The two lines have the effect of rounding the angle to (1/160)s of a degree.
'#
'# `fix` is like `trunc` in some other languages. The function truncates the
'# digits after the decimal point, irrespective of sign. For positive values
'# of `x`, `fix(x + 0.5)` is equivalent to `round(x)`.
            angle = angle * rad*160   '32
            angle=FIX(angle+.5)/rad/160  '32

'# Set `arcANGLE` to 400 pixels divided by the radius of the current object in
'# pixels.
'#
'# `P(i, 5) * pi2` is the circumference of the current object (assuming a
'# perfect circle). This is converted to pixel units by multiplying `mag/AU`,
'# which takes into account the current magnification. The value computed is the
'# circumference of the current object in pixels. The calculation is
'# mathematically equivalent to `400 / (P(i,5) * mag / AU)`.
'#
'# `arcANGLE` increases as object radius decreases. The maximum `arcANGLE` is pi
'#  which is reached when the object display radius is less than about 127.3240
'# pixels.
            arcANGLE = pi * 800/ (P(i,5)*pi2*mag/AU)
            IF arcANGLE>pi THEN arcANGLE=pi

'# This line is apparently useless as `stepANGLE` is immediately overwritten in
'# the next line without being used. `Let `stepANGLE` be 1/90 of `arcANGLE`.
            stepANGLE=arcANGLE/90

'# These lines have the approximate effect of dividing `stepANGLE` by 90, but
'# also increases it to the next largest multiple of 90 pi / (160 * 180).
'# TODO: confirm calculations
'# Let `stepANGLE` equal 160/90 of `arcANGLE` converted from radians to degrees.
'#
'# Let `stepANGLE` equal `stepANGLE + 1` truncated, then divided by the number
'# of degrees in 1 radian and by 160.
            stepANGLE=RAD*160*arcANGLE/90
            stepANGLE=FIX(stepANGLE+1)/RAD/160

'# Let ii equal `angle` (the angle from the current object to the display
'# center) minus 90 times `stepANGLE`.
            ii = angle-(90*stepANGLE)

'# If the current object is not "Mars    ", let `h = 0` and jump to `1181`.
'# Otherwise, let `ELEVangle = ii` and go to sub `8500`.
            IF i<>4 THEN h=0: goto 1181
            ELEVangle=ii:gosub 8500

1181        CirX=Px(i,3)+((h+P(i,5))*sin(ii+pi))-cenX:CirX=CirX*mag/AU
            CirY=Py(i,3)+((h+P(i,5))*cos(ii+pi))-cenY:CirY=CirY*mag/AU
            PSET (300+CirX,220+CirY),8*trail

            startANGLE = angle - (90*stepANGLE)
            stopANGLE = angle + (90*stepANGLE)
            FOR ii = startANGLE TO stopANGLE STEP stepANGLE
                IF i<>4 THEN h=0:GOTO 1182
                ELEVangle=ii:GOSUB 8500
1182            CirX=Px(i,3)+((h+P(i,5))*SIN(ii+pi))-cenX:CirX=CirX*mag/AU
                CirY=Py(i,3)+((h+P(i,5))*COS(ii+pi))-cenY:CirY=CirY*mag/AU
                LINE -(300+CirX,220+CirY), 8*trail
            NEXT ii


108     NEXT i
        GOTO 102

'# Draw "Habitat ", a structure consisting of one large circle and three
'# smaller circles on one side. TODO: elaborate
            'Paint Habitat
128         CIRCLE (300 + (Px(i, 3) - cenX) * mag / AU, 220 + (Py(i, 3) - cenY) * mag * 1 / AU), mag * P(i, 5) / AU, clr
            CIRCLE (300 + (Px(i, 3) - cenX - (P(i, 5) * .8 * SIN(vnSa))) * mag / AU, 220 + (Py(i, 3) - cenY - (P(i, 5) * .8 * COS(vnSa))) * mag * 1 / AU), mag * P(i, 5) * .2 / AU, clr
            CIRCLE (300 + (Px(i, 3) - cenX - (P(i, 5) * 1.2 * SIN(vnSa + .84))) * mag / AU, 220 + (Py(i, 3) - cenY - (P(i, 5) * 1.2 * COS(vnSa + .84))) * mag * 1 / AU), mag * P(i, 5) * .2 / AU, clr
            CIRCLE (300 + (Px(i, 3) - cenX - (P(i, 5) * 1.2 * SIN(vnSa - .84))) * mag / AU, 220 + (Py(i, 3) - cenY - (P(i, 5) * 1.2 * COS(vnSa - .84))) * mag * 1 / AU), mag * P(i, 5) * .2 / AU, clr
            RETURN

            'Paint ISS
138         FOR j = 215 TO 227 STEP 2
             LINE (300 + (Px(i, 3) - cenX + panel(0, j)) * mag / AU, 220 + (Py(i, 3) - cenY + panel(1, j)) * mag * 1 / AU)-(300 + (Px(i, 3) - cenX + panel(0, j + 1)) * mag / AU, 220 + (Py(i, 3) - cenY + panel(1, 1 + j)) * mag * 1 / AU), clr, B
            NEXT j
            RETURN

            'Paint OCESS
148         PSET (300 + (((Px(37, 3) + panel(0, 229)) - cenX) * mag / AU), 220 + (((Py(37, 3) + panel(1, 229)) - cenY) * mag / AU)), clr
            FOR j = 230 TO 238
                LINE -(300 + (((Px(37, 3) + panel(0, j)) - cenX) * mag / AU), 220 + (((Py(37, 3) + panel(1, j)) - cenY) * mag / AU)), clr
            NEXT j
            RETURN

'# Draw "AYSE    ", a circular structure with a large tubular indentation in one
'# side that goes to the center, ending in a semicircle.
            'Paint AYSE
158         Ax1 = Px(32, 3) + (500 * SIN(AYSEangle + .19 + pi))
            Ax2 = Px(32, 3) + (500 * SIN(AYSEangle - .19 + pi))
            Ay1 = Py(32, 3) + (500 * COS(AYSEangle + .19 + pi))
            Ay2 = Py(32, 3) + (500 * COS(AYSEangle - .19 + pi))
            Ax3 = Px(32, 3) + (95 * SIN(AYSEangle + (pi / 2)))
            Ax4 = Px(32, 3) + (95 * SIN(AYSEangle - (pi / 2)))
            Ay3 = Py(32, 3) + (95 * COS(AYSEangle + (pi / 2)))
            Ay4 = Py(32, 3) + (95 * COS(AYSEangle - (pi / 2)))
            Ax8 = Px(32, 3) + (100095.3 * SIN(AYSEangle + 1.5732935#))
            Ay8 = Py(32, 3) + (100095.3 * COS(AYSEangle + 1.5732935#))
            Ax9 = Px(32, 3) + (100095.3 * SIN(AYSEangle - 1.5732935#))
            Ay9 = Py(32, 3) + (100095.3 * COS(AYSEangle - 1.5732935#))

159         Ad1 = SQR((Px(28, 3) - Ax8) ^ 2 + (Py(28, 3) - Ay8) ^ 2)
            Ad2 = SQR((Px(28, 3) - Ax9) ^ 2 + (Py(28, 3) - Ay9) ^ 2)
            ad3 = SQR((Px(28, 3) - Ax1) ^ 2 + (Py(28, 3) - Ay1) ^ 2)
            clr1 = 2
            clr2 = 2
            IF Ad2 < 100090 THEN clr1 = 14
            IF Ad2 < 100085 THEN clr1 = 4
            IF Ad1 < 100090 THEN clr2 = 14
            IF Ad1 < 100085 THEN clr2 = 4
            IF Ad1 > 100080 AND Ad2 > 100080 AND ad3 < 501 GOTO 156
            IF AYSEdist > 580 THEN 156
            AYSEscrape = 10
            Vx(28) = Vx(32)
            Vy(28) = Vy(32)
            IF ad3 > 501 THEN Px(28, 3) = Px(32, 3): Py(28, 3) = Py(32, 3): GOTO 157
            P(28, 1) = Px(32, 3) + (AYSEdist * SIN(AYSEangle - 3.1415926#))
            P(28, 2) = Py(32, 3) + (AYSEdist * COS(AYSEangle - 3.1415926#))
157         GOSUB 405
            CONflag = 0

156         IF AYSEdist < 5 THEN clr = 10 ELSE clr = 12
            PSET (300 + ((Ax1 - cenX) * mag / AU), 220 + ((Ay1 - cenY) * mag / AU)), 12
            FOR j = -2.9 TO 2.9 STEP .2
                x = Px(32, 3) + (500 * SIN(j + AYSEangle))
                y = Py(32, 3) + (500 * COS(j + AYSEangle))
                LINE -(300 + ((x - cenX) * mag / AU), 220 + ((y - cenY) * mag / AU)), 12
            NEXT j
            LINE -(300 + ((Ax2 - cenX) * mag / AU), 220 + ((Ay2 - cenY) * mag / AU)), 12
            PSET (300 + ((Ax4 - cenX) * mag / AU), 220 + ((Ay4 - cenY) * mag / AU)), 12
            FOR j = -1.5 TO 1.5 STEP .2
                x = Px(32, 3) + (95 * SIN(j + AYSEangle))
                y = Py(32, 3) + (95 * COS(j + AYSEangle))
                LINE -(300 + ((x - cenX) * mag / AU), 220 + ((y - cenY) * mag / AU)), 12
            NEXT j
            LINE -(300 + ((Ax3 - cenX) * mag / AU), 220 + ((Ay3 - cenY) * mag / AU)), 12
            LINE (300 + ((Ax1 - cenX) * mag / AU), 220 + ((Ay1 - cenY) * mag / AU))-(300 + ((Ax4 - cenX) * mag / AU), 220 + ((Ay4 - cenY) * mag / AU)), 12 * clrMASK
            LINE (300 + ((Ax2 - cenX) * mag / AU), 220 + ((Ay2 - cenY) * mag / AU))-(300 + ((Ax3 - cenX) * mag / AU), 220 + ((Ay3 - cenY) * mag / AU)), 12 * clrMASK
            IF mag < 5E+09 THEN 154
            CIRCLE (300 + ((Ax1 - cenX) * mag / AU), 220 + ((Ay1 - cenY) * mag / AU)), 2, clr1 * clrMASK
            CIRCLE (300 + ((Ax1 - cenX) * mag / AU), 220 + ((Ay1 - cenY) * mag / AU)), 1, clr1 * clrMASK
154         IF mag < 5E+09 THEN 153
            CIRCLE (300 + ((Ax2 - cenX) * mag / AU), 220 + ((Ay2 - cenY) * mag / AU)), 2, clr2 * clrMASK
            CIRCLE (300 + ((Ax2 - cenX) * mag / AU), 220 + ((Ay2 - cenY) * mag / AU)), 1, clr2 * clrMASK
153         RETURN

160     IF mag < 2500000 THEN RETURN
        IF mag > 13812331090.38165# THEN mag = 13812331090.38165#
        IF mag > 4000000000# THEN st = 241 ELSE st = 239
        IF HPdisp = 1 THEN 165
        CLS
        IF cen <> 12 THEN cenXoff = Px(cen, 3) - Px(12, 3): cenYoff = Py(cen, 3) - Py(12, 3)
        cen = 12
        HPdisp = 1
        FOR j = st TO 265
            P1x = 300 + (((Px(12, 3) + (P(12, 5) * panel(1, j))) - cenX) * mag / AU)
            P1y = 220 + (((Py(12, 3) + (P(12, 5) * panel(2, j))) - cenY) * mag / AU)
            Px2 = P1x
            Py2 = P1y
            IF Px2 < 0 THEN Px2 = 0
            IF Px2 > 639 THEN Px2 = 639
            IF Py2 < 0 THEN Py2 = 0
            IF Py2 > 479 THEN Py2 = 479
            dist = SQR((Px2 - P1x) ^ 2 + (Py2 - P1y) ^ 2)
            IF dist > (mag * (panel(0, j) * P(12, 5)) / AU) - 1 THEN 164
            CIRCLE (P1x, P1y), (mag * P(12, 5) * panel(0, j) / AU), 15
            PAINT (Px2, Py2), 0, 15
            PAINT (Px2, Py2), 7, 15
            CIRCLE (P1x, P1y), (mag * P(12, 5) * panel(0, j) / AU), 7
164     NEXT j
        IF DISPflag = 0 THEN LOCATE 7, 2: PRINT "      "; : LOCATE 8, 2: PRINT "      "; : LOCATE 9, 2: PRINT "      ";
        IF DISPflag = 0 THEN GOSUB 400
165     RETURN 109

        'Landing on Hyperion
166     Rmin = 1E+26
        AtargPRIME = angle
        IF ref = 12 AND B(1, i) = 28 THEN Vref = SQR(G * P(B(0, i), 4) / r): Aref = angle: Dref = r
        IF Ltr = 12 THEN LtrA = a
        FOR j = 241 TO 265
            Px2 = (Px(12, 3) + (P(12, 5) * panel(1, j)))
            Py2 = (Py(12, 3) + (P(12, 5) * panel(2, j)))
            Rcrit = (P(12, 5) * panel(0, j)) + P(B(1, i), 5)
            difX = Px(B(1, i), 3) - Px2
            difY = Py(B(1, i), 3) - Py2
            r = SQR((difY ^ 2) + (difX ^ 2))
            IF r - Rcrit < Rmin THEN Rmin = r - Rcrit: rD = r: PH5prime = P(12, 5) * panel(0, j)
            IF r > Rcrit THEN 167
            IF i = 136 THEN CONflag2 = 1: CONflag3 = 12: RETURN 5 ' targ = 32: RETURN 5
            IF i = 230 THEN explCENTER = 39: GOSUB 6000: RETURN 5
            IF i = 195 THEN explCENTER = 39: GOSUB 6000: RETURN 5
            CONflag = 1: Acon1 = angle: CONacc = a
            RcritL2 = P(12, 5) - PH5prime
            Vx(28) = Vx(12)
            Vy(28) = Vy(12)
            GOSUB 5000
            CONflag = 1: CONtarg = 12: Dcon = r: Acon = angle
            IF r >= Rcrit - .5 THEN 169
            eng = 0: explFLAG1 = 1
            Px(28, 3) = Px2 + ((Rcrit - .1) * SIN(Acon + 3.1415926#))
            Py(28, 3) = Py2 + ((Rcrit - .1) * COS(Acon + 3.1415926#))
169         IF COS(Acon - Acon1) > 0 THEN 168
            Px(28, 3) = Px2 + ((Rcrit + .1) * SIN(Acon + 3.1415926#))
            Py(28, 3) = Py2 + ((Rcrit + .1) * COS(Acon + 3.1415926#))
            GOTO 168
167     NEXT j
168     IF i = 79 AND targ = 12 THEN Dtarg = rD: RcritL = P(12, 5) - PH5prime: Atarg = AtargPRIME: Acctarg = a
        RETURN 106

        'Detect contact with an object
102     IF CONflag = 0 THEN 112
        MATCHaacc=0
        CONSTacc=0
        vector = COS(THRUSTangle - Acon)
        IF CONtarg > 37 THEN ufo2 = 0: explFLAG1 = 1: eng = 0: targ = ref: GOTO 112
        IF ((Dcon - P(CONtarg, 5) - P(28, 5) + RcritL2) <= 0) AND ((Aacc + Av + Are) * vector < CONacc * 1.01) THEN Vx(28) = Vx(CONtarg): Vy(28) = Vy(CONtarg)
        IF CONtarg = 12 THEN 112
        IF vector >= 0 THEN 193
            Pvx = P(CONtarg, 4)
            IF Pvx < 1 THEN Pvx = 1
            Vx(CONtarg) = Vx(CONtarg) + (THRUSTx * ts * HABmass / Pvx): Vx(28) = Vx(CONtarg)
            Vy(CONtarg) = Vy(CONtarg) + (THRUSTy * ts * HABmass / Pvx): Vy(28) = Vy(CONtarg)
193     IF ((Dcon - P(CONtarg, 5) - P(28, 5)) > -.5) THEN GOTO 112
194     eng = 0
        ALTdel=0
        IF CONtarg=4 THEN ALTdel=MARSelev
        Px(28, 3) = Px(CONtarg, 3) + ((P(CONtarg, 5) + P(28, 5) - .1 + ALTdel) * SIN(Acon + 3.1415926#))
        Py(28, 3) = Py(CONtarg, 3) + ((P(CONtarg, 5) + P(28, 5) - .1 + ALTdel) * COS(Acon + 3.1415926#))
        explFLAG1 = 1

        'Docked with AYSE drive module
112     explFLAG2 = 0
        IF AYSE = 150 THEN Vx(32) = Vx(28): Vy(32) = Vy(28): Px(32, 3) = Px(28, 3): Py(32, 3) = Py(28, 3): AYSEangle = Sangle
        IF CONflag2 = 1 AND CONflag4 = 0 THEN CONflag4 = 1: explFLAG2 = 1
        IF CONflag2 = 1 AND CONflag3 < 38 THEN Vx(32) = Vx(CONflag3): Vy(32) = Vy(CONflag3)


        'Update object positions
        FOR i = 0 TO 37 + ufo1 + ufo2
            Px(i, 3) = Px(i, 3) + (Vx(i) * ts)
            Py(i, 3) = Py(i, 3) + (Vy(i) * ts)
        NEXT i


        IF ts > 10 THEN GOSUB 3100
        IF MODULEflag > 0 THEN Px(36, 3) = P(36, 1) + Px(MODULEflag, 3): Py(36, 3) = P(36, 2) + Py(MODULEflag, 3): Vx(36) = Vx(MODULEflag): Vy(36) = Vy(MODULEflag)
        Px(37, 3) = 4446370.8284487# + Px(3, 3): Py(37, 3) = 4446370.8284487# + Py(3, 3): Vx(37) = Vx(3): Vy(37) = Vy(3)

        'Record new center position
        OLDcenX=cenX
        OLDcenY=cenY
        cenX = Px(cen, 3) + cenXoff
        cenY = Py(cen, 3) + cenYoff

'# After erasing and leaving trails
        'Repaint objects to the screen
111     FOR i = 37 + ufo1 + ufo2 TO 0 STEP -1
            IF i = 36 AND MODULEflag = 0 THEN 109
            if i=4 then 11911
            IF SQR(((Px(i, 3) - cenX) * mag / AU) ^ 2 + ((Py(i, 3) - cenY) * mag * 1 / AU) ^ 2) - (P(i, 5) * mag / AU) > 400 THEN 109

11911       pld = 0
            IF i = 28 THEN pld = 2 * ABS(SGN(eng))
            IF mag * P(i, 5) / AU < 1.1 THEN CIRCLE (300 + (Px(i, 3) - cenX) * mag / AU, 220 + (Py(i, 3) - cenY) * mag * 1 / AU), 1, P(i, 0) + pld: GOTO 109
            IF i = 28 THEN clr = 12 + pld: vnSa = Sangle: GOSUB 128: GOTO 109
            IF i = 35 THEN clr = 12: GOSUB 138: GOTO 109
            IF i = 37 THEN clr = 12: GOSUB 148: GOTO 109
            IF i = 32 THEN clrMASK = 1: GOSUB 158: GOTO 109
            IF i = 12 THEN GOSUB 160
            IF P(i,5)*mag/AU > 300 THEN 119
            CIRCLE (300 + (Px(i, 3) - cenX) * mag / AU, 220 + (Py(i, 3) - cenY) * mag * 1 / AU), mag * P(i, 5) / AU, P(i, 0) + pld: GOTO 109

119         difX = cenX-Px(i, 3)
            difY = cenY-Py(i, 3)
            dist = (SQR((difY ^ 2) + (difX ^ 2)) - P(i, 5)) * mag / AU
            GOSUB 5000

            angle = angle * rad * 160
            angleALT=angle
            angle=fix(angle+.5)/rad/160
            arcANGLE = pi * 800/ (P(i,5)*pi2*mag/AU)
            IF arcANGLE>pi THEN arcANGLE=pi

            stepANGLE=RAD*160*arcANGLE/90
            stepANGLE=FIX(stepANGLE+1)/RAD/160
            ii = angle-(90*stepANGLE)
            IF i<>4 THEN h=0: GOTO 1191
            ELEVangle=ii:GOSUB 8500

1191        CirX=Px(i,3)+((h+P(i,5))*sin(ii+pi))-cenX:CirX=CirX*mag/AU
            CirY=Py(i,3)+((h+P(i,5))*cos(ii+pi))-cenY:CirY=CirY*mag/AU
            PSET (300+CirX,220+CirY),P(i, 0)

            startANGLE = angle - (90*stepANGLE)
            stopANGLE = angle + (90*stepANGLE)
            FOR ii = startANGLE to stopANGLE STEP stepANGLE
                if i<>4 then h=0:goto 1192
                ELEVangle=ii:gosub 8500

1192            CirX=Px(i,3)+((h+P(i,5))*sin(ii+pi))-cenX:CirX=CirX*mag/AU
                CirY=Py(i,3)+((h+P(i,5))*cos(ii+pi))-cenY:CirY=CirY*mag/AU
                LINE -(300+CirX,220+CirY), P(i, 0)
            NEXT ii

109     NEXT i


        'Calculate parameters for landing target
        IF targ < 40 THEN 179
        IF SQR(((Px(40, 3) - OLDcenX) * mag / AU) ^ 2 + ((Py(40, 3) - OLDcenY) * mag * 1 / AU) ^ 2) < 401 THEN PSET (300 + (Px(40, 3) - OLDcenX) * mag / AU, 220 + (Py(40, 3) - OLDcenY) * mag * 1 / AU), 8 * trail
        Px(40, 3) = Px(Ltr, 3) + Ltx
        Py(40, 3) = Py(Ltr, 3) + Lty
        IF SQR(((Px(40, 3) - cenX) * mag / AU) ^ 2 + ((Py(40, 3) - cenY) * mag * 1 / AU) ^ 2) < 401 THEN PSET (300 + (Px(40, 3) - cenX) * mag / AU, 220 + (Py(40, 3) - cenY) * mag * 1 / AU), 14
        Vx(40) = Vx(Ltr)
        Vy(40) = Vy(Ltr)
        difX = Px(28, 3) - Px(40, 3)
        difY = Py(28, 3) - Py(40, 3)
        Dtarg = SQR((difY ^ 2) + (difX ^ 2))
        GOSUB 5000
        Atarg = angle
        IF Dtarg = 0 THEN 179
        Acctarg = LtrA + ((((Vx(28) - Vx(targ)) ^ 2 + (Vy(28) - Vy(targ)) ^ 2) / (2 * (Dtarg))))

179     oldSa = Sangle

        'Calculate angle from target to reference object
        IF targ = ref THEN Atargref = 0: GOTO 114
        difX = Px(targ, 3) - Px(ref, 3)
        difY = Py(targ, 3) - Py(ref, 3)
        r = SQR((difY ^ 2) + (difX ^ 2))
        GOSUB 5000
        Atr = angle
        Atargref = ABS(angle - Aref)
        IF Atargref > 3.1415926535# THEN Atargref = 6.283185307# - Atargref


        'Re-paint target vector
114     IF DISPflag = 0 THEN LINE (30, 120)-(30 + (20 * SIN(Atarg)), 120 + (20 * COS(Atarg))), 8


        'Repaint velocity and orientation vectors
        difX = Vx(targ) - Vx(28)
        difY = Vy(targ) - Vy(28)
        GOSUB 5000
        Vvangle = angle

        IF DISPflag = 0 THEN LINE (30, 120)-(30 + (10 * SIN(Vvangle)), 120 + (10 * COS(Vvangle))), 12
        IF DISPflag = 0 THEN LINE (30, 120)-(30 + (5 * SIN(Sangle)), 120 + (5 * COS(Sangle))), 10
        IF DISPflag = 0 THEN PSET (30, 120), 1
        IF SQR(((Px(28, 3) - cenX) * mag / AU) ^ 2 + ((Py(28, 3) - cenY) * mag * 1 / AU) ^ 2) > 400 THEN 133
        IF vflag = 1 THEN LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (30 * SIN(Atarg)) + (Px(28, 3) - cenX) * mag / AU, 220 + (30 * COS(Atarg)) + (Py(28, 3) - cenY) * mag * 1 / AU), 8
        IF vflag = 1 THEN LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (20 * SIN(Vvangle)) + (Px(28, 3) - cenX) * mag / AU, 220 + (20 * COS(Vvangle)) + (Py(28, 3) - cenY) * mag * 1 / AU), 12
        IF vflag = 1 THEN LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (10 * SIN(Sangle)) + (Px(28, 3) - cenX) * mag / AU, 220 + (10 * COS(Sangle)) + (Py(28, 3) - cenY) * mag * 1 / AU), 10
133     VangleDIFF = Atarg - Vvangle


        'Cause explosion
        IF Ztel(5) = 1 THEN Ztel(5) = 0: explFLAG1 = 1: explosion = 0
        IF Ztel(6) = 1 THEN Ztel(6) = 0: explFLAG2 = 1: explosion1 = 0
        IF explFLAG1 = 1 AND explosion = 0 THEN explCENTER = 28: GOSUB 6000
        IF explFLAG2 = 1 AND explosion1 = 0 THEN explCENTER = 32: GOSUB 6000


        'Update simulation time
        sec = sec + ts
        IF sec > 60 THEN min = min + 1: sec = sec - 60
        IF min = 60 THEN hr = hr + 1: min = 0
        IF hr = 24 THEN day = day + 1: hr = 0
        dayNUM = 365
        IF INT(year / 4) * 4 = year THEN dayNUM = 366
        IF INT(year / 100) * 100 = year THEN dayNUM = 365
        IF INT(year / 400) * 400 = year THEN dayNUM = 366
        IF day = dayNUM + 1 THEN year = year + 1: day = 1

        IF dte = 0 THEN 121
        IF dte > 1 THEN GOSUB 8100: GOTO 121
        LOCATE 25, 58: PRINT "   ";
        PRINT USING "####_ "; year;
        LOCATE 25, 66: PRINT USING "###"; day; hr; min;
        IF ts < 60 THEN LOCATE 25, 75: PRINT USING "###"; sec;

        'Print Simulation data
121     IF targ = 40 THEN 123
        IF COS(VangleDIFF) <> 0 AND Dtarg - P(targ, 5) <> 0 THEN Acctarg = Acctarg + ((((Vx(28) - Vx(targ)) ^ 2 + (Vy(28) - Vy(targ)) ^ 2) / (2 * (Dtarg - P(targ, 5)))) * COS(VangleDIFF))
123     oldAcctarg = Acctarg
        IF DISPflag = 1 THEN 113
        COLOR 12
        LOCATE 23, 8: IF Ztel(17) = 1 THEN PRINT "P";  ELSE PRINT " ";
        LOCATE 24, 8: IF PROBEflag = 1 THEN PRINT "L";  ELSE PRINT " ";
        LOCATE 8, 16: IF CONSTacc = 1 THEN PRINT CHR$(67 + (10 * MATCHacc));  ELSE PRINT " ";
        COLOR 15
        targDISP = 1
        IF LOS + RADAR + INS = 0 THEN targDISP = 0
        IF LOS + INS = 0 AND Dtarg > 1E+09 THEN targDISP = 0
        IF targDISP = 0 THEN 129
        LOCATE 2, 12
        IF (64 AND NAVmalf) = 64 THEN print "-----------";: goto 143
        IF Vref > 9999999 THEN PRINT USING "##.####^^^^"; Vref ELSE PRINT USING "########.##"; Vref;
143     Vrefhab = SQR((Vx(28) - Vx(ref)) ^ 2 + (Vy(28) - Vy(ref)) ^ 2)
        LOCATE 3, 12
        IF Vrefhab > 9999999 THEN PRINT USING "##.####^^^^"; Vrefhab;  ELSE PRINT USING "########.##"; Vrefhab;
        Vreftarg = SQR((Vx(targ) - Vx(ref)) ^ 2 + (Vy(targ) - Vy(ref)) ^ 2)
        LOCATE 4, 12
        IF Vreftarg > 9999999 THEN PRINT USING "##.####^^^^"; Vreftarg;  ELSE PRINT USING "########.##"; Vreftarg;
        LOCATE 14, 7
        IF (32 AND NAVmalf) = 32 THEN print "---------";: goto 144
        IF ABS(Acctarg) > 9999 THEN PRINT USING "##.##^^^^"; Acctarg;  ELSE PRINT USING "######.##"; Acctarg;
144     LOCATE 13, 2
        Dfactor = 1000
        IF Dtarg > 9.9E+11 THEN zDISP$ = "##.########^^^^": GOTO 125
        IF INS = 0 THEN zDISP$ = "#########_00.000": Dfatctor = 100000 ELSE zDISP$ = "##########_0.000": Dfactor = 10000
        IF RADAR = 2 AND Dtarg < 1E+09 THEN zDISP$ = "###########.###": Dfactor = 1000
125     PRINT USING zDISP$; (Dtarg - P(targ, 5) - P(28, 5) + RcritL) / Dfactor;
        LOCATE 15, 9: PRINT USING "####.##"; Atargref * RAD;
129     IF Cdh > .0005 THEN COLOR 14
        LOCATE 7, 8: IF Cdh < .0005 THEN PRINT USING "#####.###"; Are;  ELSE PRINT USING "#####.##"; Are; : PRINT "P";
        COLOR 15
        LOCATE 8, 8: PRINT USING "#####.##"; Aacc;
        LOCATE 11, 6
        IF Dfuel = 0 THEN PRINT "H"; : PRINT USING "#########"; fuel; : PRINT CHR$(32 + (refuel * 11) + (ventfuel * 13));
        IF Dfuel = 1 THEN PRINT "A"; : PRINT USING "#########"; AYSEfuel; : PRINT CHR$(32 + (AYSErefuel * 11) + (AYSEventfuel * 13));
        IF Dfuel = 2 THEN PRINT "RCS"; : PRINT USING "#######"; vernP!;
        LOCATE 18, 9
        IF (16 AND NAVmalf) = 16 THEN print "-------";: goto 124
        PRINT USING "####.##"; DIFFangle;

124     COLOR 15
        GOSUB 3005
        GOSUB 3008
        GOSUB 3006


113     'Timed back-up
        IF bkt - TIMER > 120 THEN bkt = TIMER
        IF bkt + 1 < TIMER THEN bkt = TIMER: GOSUB 800
        IF ufo2 = 1 THEN Px(39, 1) = Px(39, 1) - 1
        IF ufo2 = 1 AND Px(39, 1) < 1 THEN explCENTER = 39: GOSUB 6000
        IF COLeventTRIG = 1 THEN ts = .125: TSindex=4
        OLDts = ts


        'Control input
103     z$ = INKEY$
        IF z$ = "" THEN 105
        IF z$ = "q" THEN GOSUB 900
        IF z$ = "`" THEN DISPflag = 1 - DISPflag: CLS : HPdisp = 0: IF DISPflag = 0 THEN GOSUB 405
        'IF z$ = CHR$(27) THEN GOSUB 910
        IF z$ = " " THEN cen = targ: cenXoff = Px(28, 3) - Px(cen, 3): cenYoff = Py(28, 3) - Py(cen, 3)
        IF z$ = CHR$(9) THEN Aflag = Aflag + 1: IF Aflag = 3 THEN Aflag = 0: GOSUB 400 ELSE GOSUB 400
        IF z$ = CHR$(0) + ";" THEN Sflag = 1: GOSUB 400
        IF z$ = CHR$(0) + "<" THEN Sflag = 0: GOSUB 400
        IF z$ = CHR$(0) + "=" THEN Sflag = 4: GOSUB 400
        IF z$ = CHR$(0) + ">" THEN Sflag = 2: GOSUB 400
        IF z$ = CHR$(0) + "?" THEN Sflag = 3: GOSUB 400
        IF z$ = "b" THEN Dfuel = Dfuel + 1: GOSUB 400
        IF z$ = CHR$(0) + "A" THEN Sflag = 5: GOSUB 400
        IF z$ = CHR$(0) + "B" THEN Sflag = 6: GOSUB 400
        IF z$ = CHR$(0) + "C" THEN OFFSET = -1 * (1 - ABS(OFFSET)): GOSUB 400
        IF z$ = CHR$(0) + "D" THEN OFFSET = 1 - ABS(OFFSET): GOSUB 400
        IF z$ = CHR$(0) + CHR$(134) THEN CONSTacc = 1 - CONSTacc: Accel = Aacc: MATCHacc = 0
        IF z$ = CHR$(0) + CHR$(133) THEN MATCHacc = 1 - MATCHacc: CONSTacc = MATCHacc

        IF z$ = "+" AND mag < 130000000000# THEN mag = mag / .75: GOSUB 405
        IF z$ = "-" AND mag > 6.8E-11 THEN mag = mag * .75:  GOSUB 405


        IF vernP! <= 0 THEN 115
        IF z$ <> CHR$(0) + "I" THEN 116
        IF (8192 AND NAVmalf) = 8192 THEN 115
        HABrotateADJ% = HABrotateADJ% - 1
        vernP! = vernP! - 1
116     IF z$ <> CHR$(0) + "G" THEN 115
        IF (4096 AND NAVmalf) = 4096 THEN 115
        HABrotateADJ% = HABrotateADJ% + 1
        vernP! = vernP! - 1


115     IF z$ = "[" THEN GOSUB 460
        IF z$ = "]" THEN GOSUB 465
        IF z$ < "0" OR z$ > "U" THEN 110
        z = ASC(z$) - 48
        IF z = 36 AND MODULEflag = 0 THEN 110
        IF Aflag = 0 THEN cen = z: cenXoff = 0: cenYoff = 0: GOSUB 405
        IF z = 28 THEN 110
        IF Aflag = 1 THEN targ = z: GOSUB 400
        IF Aflag = 2 THEN ref = z: GOSUB 400


110     IF z$ = "e" THEN ENGsetFLAG = 1 - ENGsetFLAG
        IF z$ = CHR$(0) + "S" THEN eng = eng + .1: GOSUB 400
        IF z$ = CHR$(0) + "R" THEN eng = eng - .1: GOSUB 400
        IF z$ = CHR$(0) + "Q" THEN eng = eng + 1: GOSUB 400
        IF z$ = CHR$(0) + "O" THEN eng = eng - 1: GOSUB 400
        IF z$ = "\" THEN eng = eng * -1: GOSUB 400
        IF z$ = CHR$(13) THEN eng = 100: GOSUB 400
        IF z$ = CHR$(8) THEN eng = 0: MATCHacc = 0: CONSTacc = 0: GOSUB 400
        IF z$ = CHR$(0) + "H" THEN vern = .1: vernA = 0
        IF z$ = CHR$(0) + "K" THEN vern = .1: vernA = 90
        IF z$ = CHR$(0) + "M" THEN vern = .1: vernA = -90
        IF z$ = CHR$(0) + "P" THEN vern = .1: vernA = 180

        IF z$ <> "v" THEN 107
        vflag = 1 - vflag
        LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (20 * SIN(Vvangle)) + (Px(28, 3) - cenX) * mag / AU, 220 + (20 * COS(Vvangle)) + (Py(28, 3) - cenY) * mag * 1 / AU), 0
        LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (30 * SIN(Atarg)) + (Px(28, 3) - cenX) * mag / AU, 220 + (30 * COS(Atarg)) + (Py(28, 3) - cenY) * mag * 1 / AU), 0
        LINE (300 + (Px(28, 3) - cenX) * mag / AU, 220 + (Py(28, 3) - cenY) * mag * 1 / AU)-(300 + (10 * SIN(Sangle)) + (Px(28, 3) - cenX) * mag / AU, 220 + (10 * COS(Sangle)) + (Py(28, 3) - cenY) * mag * 1 / AU), 0
107     IF z$ = "t" THEN trail = 1 - trail
        IF z$ = "l" THEN ORref = 1 - ORref: GOSUB 405
        IF z$ = "a" THEN PROBEflag = 1 - PROBEflag
        IF z$ = CHR$(0) + "@" THEN Sflag = 7: angleOFFSET = (Atarg - Sangle): GOSUB 400
        IF z$ = "u" THEN tr = 1 - tr
        IF z$ = "d" THEN dte = dte + 1: LOCATE 25, 58: PRINT SPACE$(20); : GOSUB 400
        IF dte = 4 THEN dte = 0
        IF z$ = "p" THEN PROJflag = 1 - PROJflag: GOSUB 400
        IF z$ = "o" THEN GOSUB 3000
        IF z$ = "c" THEN GOSUB 405
        'IF z$ = "z" THEN Ztel(7) = 1 - SGN(Ztel(7))
        'IF z$ = "x" THEN Ztel(7) = 2 - (SGN(Ztel(7)) * 2)
        'IF z$ = "w" THEN SRBtimer = 220
        IF Ztel(8) = 1 THEN 105
        IF z$ <> "/" THEN 104
        IF TSindex < 2 THEN 105
        TSindex = TSindex - 1
        ts=TSflagVECTOR(TSindex)
        GOSUB 400

104     IF z$ <> "*" THEN 105
        IF TSindex > 16 THEN 105
        TSindex = TSindex + 1
        ts=TSflagVECTOR(TSindex)
        GOSUB 400

105     IF z$ = "s" THEN GOSUB 600
        IF z$ = "r" THEN GOSUB 700
        IF tttt - TIMER > ts * 10 THEN tttt = TIMER + (ts / 2)
        IF TSindex < 6 and TIMER - tttt < ts THEN 103
        IF TSindex = 6 and TIMER - tttt < .01 THEN 103
        GOTO 100


        'SUBROUTINE Automatic space craft orientation calculations
301     IF explosion > 1 THEN Ztel(2) = 0: Ztel(1) = 1
        IF ufo1 = 0 AND Ztel(17) = 1 AND PROBEflag = 1 THEN GOSUB 7000: PROBEflag = 0
        IF explosion1 > 1 AND AYSE = 150 THEN Ztel(2) = 0
        IF Ztel(1) = 1 THEN Sflag = 1: MATCHacc = 0: CONSTacc = 0
        IF SRBtimer > 0 THEN SRBtimer = SRBtimer - ts
        IF SRBtimer > 100 THEN SRB = 131250 ELSE SRB = 0
        IF vernP! < .01 THEN vernP! = 0
        IF ABS(HABrotMALF) * ABS(eng) > .0001 THEN Sflag = 1
        IF (NAVmalf and 3840)>0 THEN Sflag=1
        IF ABS(HABrotate + .5) < .5 * (1 - (vernCNT * .8)) THEN HABrotate = 0
        HABrotate = HABrotate + (HABrotateADJ% * (10 ^ (-1 * vernCNT)))
        HABrotateADJ% = HABrotateADJ% * vernCNT
        HABrotate = HABrotate + (eng * HABrotMALF * .0095 * SGN(Ztel(2)))
        HABrotate = HABrotate + (SGN(vernP!) * (((768 AND NAVmalf) / 256) * .015))
        HABrotate = HABrotate - (SGN(vernP!) * (((3072 AND NAVmalf) / 1024) * .015))
        IF ABS(HABrotate) > 99 THEN HABrotate = SGN(HABrotate) * 99
        IF ABS(HABrotateADJ%) > 10 THEN HABrotateADJ% = SGN(HABrotateADJ%) * 10

        COLOR 15
        Aoffset = ATN((P(targ, 5) * 1.01) / (Dtarg + .0001)): Atarg = Atarg - (Aoffset * OFFSET)
        difX = Vx(targ) - Vx(28)
        difY = Vy(targ) - Vy(28)
        GOSUB 5000
        Vvtangle = angle
        IF ORref = 1 THEN Aa = Atarg ELSE Aa = Aref
        IF PROJflag = 0 THEN DIFFangle = (Aa - Sangle) * RAD ELSE DIFFangle = (Atarg - Vvtangle) * RAD
        IF DIFFangle > 180 THEN DIFFangle = -360 + DIFFangle
        IF DIFFangle < -180 THEN DIFFangle = 360 + DIFFangle

        difX = Px(28, 3) - Px(Ztel(14), 3)
        difY = Py(28, 3) - Py(Ztel(14), 3)
        GOSUB 5000
        Wangle = angle
        VwindX = (Ztel(15) * SIN(Wangle + Ztel(16)))
        VwindY = (Ztel(15) * COS(Wangle + Ztel(16)))

        IF CONflag < .5 THEN 303
        IF CONtarg = 32 THEN 303
        HABrotate = 0
        IF Sflag = 3 THEN Sangle = Aref - (180 / RAD) ELSE Sflag = 1: LOCATE 25, 11: PRINT "MAN      ";
303     IF (3840 AND NAVmalf) > 0 THEN vernP! = vernP! - .5: Sflag = 10
        IF Sflag = 2 AND (1 AND NAVmalf) = 1 THEN Sflag = 10
        IF Sflag = 7 AND (1 AND NAVmalf) = 1 THEN Sflag = 10
        IF Sflag = 5 AND (1 AND NAVmalf) = 1 THEN Sflag = 10
        IF Sflag = 6 AND (1 AND NAVmalf) = 1 THEN Sflag = 10
        IF Sflag = 0 AND (4 AND NAVmalf) = 4 THEN Sflag = 10
        IF Sflag = 4 AND (4 AND NAVmalf) = 4 THEN Sflag = 10
        IF Sflag = 3 AND (4 AND NAVmalf) = 4 THEN Sflag = 10
        IF vernP! < .01 AND Sflag <> 1 THEN Sflag = 10
        IF Sflag = 10 THEN Sflag = 1: LOCATE 25, 11: PRINT "MAN      ";
        IF Sflag = 1 THEN Sangle = Sangle + (HABrotate * .0086853 * ts): GOTO 302
        vernP! = vernP! - .01
        IF Sflag = 2 THEN dSangle = Atarg ELSE dSangle = Aref
        IF Sflag = 7 THEN dSangle = Atarg
        dSangle = dSangle - (Aoffset * OFFSET)
        IF Sflag = 5 THEN dSangle = Vvtangle
        IF Sflag = 6 THEN dSangle = Vvtangle + 3.1415926535#
        IF Sflag = 0 THEN dSangle = dSangle - (90 / RAD)
        IF Sflag = 4 THEN dSangle = dSangle + (90 / RAD)
        IF Sflag = 3 THEN dSangle = dSangle - (180 / RAD)
        IF Sflag = 7 THEN dSangle = dSangle - angleOFFSET
        diffSangle = dSangle - Sangle
        IF diffSangle > pi THEN diffSangle = (-1 * pi2) + diffSangle
        IF diffSangle < (-1 * pi) THEN diffSangle = pi2 + diffSangle
        IF ABS(diffSangle) < .24 * ts THEN Sangle = dSangle: HABrotate = 0: GOTO 302
        Sangle = Sangle + (.2 * ts * SGN(diffSangle))
        HABrotate = 23 * SGN(diffSangle)

302     IF Sangle < 0 THEN Sangle = Sangle + pi2
        IF Sangle > pi2 THEN Sangle = Sangle - pi2
        IF oldAcctarg < 0 THEN MATCHacc = 0
        IF DISPflag = 1 THEN 307
        LOCATE 5, 16: COLOR 8 + (7 * ENGsetFLAG): PRINT USING "####.#_ "; eng;
        IF Sflag <> 1 THEN 307
        IF HABrotate <> 0 THEN COLOR 15 ELSE COLOR 8
        LOCATE 25, 15: PRINT USING "##.#"; ABS(HABrotate) / 2;
        IF (NAVmalf AND 11264)>0 THEN COLOR 12:rotSYMB$=">" ELSE COLOR 10:rotSYMB$=" "
        LOCATE 25, 19: IF HABrotate < 0 THEN PRINT ">";  ELSE PRINT rotSYMB$;
        IF (NAVmalf AND 4864)>0 THEN COLOR 12:rotSYMB$="<" ELSE COLOR 10:rotSYMB$=" "
        LOCATE 25, 14: IF HABrotate > 0 THEN PRINT "<";  ELSE PRINT rotSYMB$;

307     COLOR 15
        IF Ztel(2) = 0 THEN MATCHacc = 0: CONSTacc = 0
        IF MATCHacc = 1 THEN Accel = oldAcctarg
        HABmass = 275000 + fuel
        IF AYSE = 150 THEN HABmass = HABmass + 20000000 + AYSEfuel
        massDEL = (1 - ((Vx(28) ^ 2 + Vy(28) ^ 2) / 300000000 ^ 2))
        IF massDEL < 9.999946E-41 THEN massDEL = 9.999946E-41
        HABmass = HABmass / SQR(massDEL)
        IF CONSTacc = 1 THEN Aacc = Accel: eng = ENGsetFLAG * Aacc * HABmass / Ztel(2) ELSE Aacc = (ENGsetFLAG * Ztel(2) * eng) / HABmass
        Av = (175000 * vern) / HABmass
        IF AYSE = 150 THEN Av = 0
        IF vernP! <= 0 THEN Av = 0
        IF Av > 0 THEN vernP! = vernP! - 1
        vern = 0

304     Aacc = Aacc + (SRB / HABmass) * 100
        P(i, 1) = P(i, 1) + (Aacc * SIN(Sangle))
        P(i, 2) = P(i, 2) + (Aacc * COS(Sangle))
        P(i, 1) = P(i, 1) + Av * SIN(Sangle + (vernA / RAD))
        P(i, 2) = P(i, 2) + Av * COS(Sangle + (vernA / RAD))


        THRUSTx = (Aacc * SIN(Sangle))
        THRUSTy = (Aacc * COS(Sangle))
        THRUSTx = THRUSTx + (Av * SIN(Sangle + (vernA / RAD)))
        THRUSTy = THRUSTy + (Av * COS(Sangle + (vernA / RAD)))

        Are = 0
        IF atm = 40 AND Ztel(16) <> 3.141593 THEN Are = 0: GOTO 319
        difX = Vx(atm) - Vx(28) + VwindX
        difY = Vy(atm) - Vy(28) + VwindY
        GOSUB 5000
        VvRangle = angle
        AOA = ((COS(VvRangle - Sangle))) * SGN(SGN(COS(VvRangle - Sangle)) - 1)
        AOA = AOA * AOA * AOA
        IF AOA > .5 THEN AOA = 1 - AOA
        AOA = (AOA * SGN(SIN(VvRangle - Sangle))) * .5
        AOAx = -1 * ABS(AOA) * SIN(VvRangle + (1.5708 * SGN(AOA)))
        AOAy = -1 * ABS(AOA) * COS(VvRangle + (1.5708 * SGN(AOA)))
        VVr = SQR((difX ^ 2) + (difY ^ 2))
        IF atm = 40 THEN Pr = .01: GOTO 320
        IF Ratm < 0 THEN Pr = P(atm, 8) ELSE Pr = P(atm, 8) * (2.71828 ^ (-1 * Ratm / P(atm, 9)))
320     Are = Pr * VVr * VVr * Cdh
        IF Are * ts > VVr / 2 THEN Are = (VVr / 2) / ts
        IF CONflag = 1 AND Ztel(16) = 0 THEN Are = 0
        P(i, 1) = P(i, 1) - (Are * SIN(VvRangle)) + (Are * AOAx)
        P(i, 2) = P(i, 2) - (Are * COS(VvRangle)) + (Are * AOAy)
        THRUSTx = THRUSTx - (Are * SIN(VvRangle))
        THRUSTy = THRUSTy - (Are * COS(VvRangle))
321     IF Pr > 100 AND Pr / 200 > RND THEN explFLAG1 = 1

319     Agrav = (THRUSTx - (Are * SIN(VvRangle))) ^ 2
        Agrav = Agrav + ((THRUSTy - (Are * COS(VvRangle))) ^ 2)
        Agrav = SQR(Agrav)
        IF CONflag = 1 THEN Agrav = CONacc

        IF THRUSTy = 0 THEN IF THRUSTy < 0 THEN THRUSTangle = .5 * 3.1415926535# ELSE THRUSTangle = 1.5 * 3.1415926535# ELSE THRUSTangle = ATN(THRUSTx / THRUSTy)
        IF THRUSTy > 0 THEN THRUSTangle = THRUSTangle + 3.1415926535#
        IF THRUSTx > 0 AND THRUSTy < 0 THEN THRUSTangle = THRUSTangle + 6.283185307#

        IF DISPflag = 1 THEN 330
        LOCATE 5, 8: COLOR 14
        IF SRB > 10 THEN PRINT "SRB";  ELSE PRINT "   ";
        IF AYSE = 150 THEN COLOR 10 ELSE COLOR 0
        LOCATE 5, 12: PRINT "AYSE";
        COLOR 7

330     RETURN



        'SUBROUTINE print control variable names to screen
405     CLS

'# `HPdisp` (possibly standing for "Hyperion display") appears to be a
'# variable controlling the drawing of "Hyperion". TODO: confirm.
        HPdisp = 0
400     IF mag < .1 THEN GOSUB 8000

'# Clamp the minimum and maximum `ts` to 0.015625 and 60 respectively and
'# update `TSindex` to be either the smallest or largest one if `ts` is out
'# of bounds.
        IF ts < .015625 THEN ts = .015626:TSindex=1
        IF ts > 60 THEN ts = 60:TSindex=17

'# TODO: understand.
        IF Dfuel > 2 THEN Dfuel = 0
        IF ufo2 = 1 THEN ts = .25: TSindex=5
        COLOR 8

'# Indexes `1-214` of `panel` are used to draw the box of the "panel" at the
'# left side of the display in the main flight screen.
'#
'# TODO: find what `dte` and `j` do.
        FOR j = 1 TO 214
            LOCATE panel(0, j), panel(1, j): PRINT CHR$(panel(2, j));
            IF dte = 0 AND j = 168 THEN 403
        NEXT j

403     COLOR 7

'# TODO: understand
        IF Ztel(1) = 1 THEN Sflag = 1

'# Output labels
        LOCATE 2, 2: PRINT "ref Vo   ";
        LOCATE 3, 2: PRINT "V hab-ref";
        LOCATE 4, 2: PRINT "Vtarg-ref";

        COLOR 7

'# Output engine throttle label and engine throttle setting in dark gray if
'# `ENGsetFLAG` is 0 and light gray if it is 1, using the format string
'# `"####.#_ "`.
        LOCATE 5, 2: PRINT "Engine"; : LOCATE 5, 16: COLOR 8 + (7 * ENGsetFLAG): PRINT USING "####.#_ "; eng;
        COLOR 7 + (5 * Ztel(1))
        LOCATE 25, 2: PRINT "NAVmode";
        COLOR 14
        LOCATE 25, 10
        IF OFFSET = -1 THEN PRINT "-";
        IF OFFSET = 0 THEN PRINT " ";
        IF OFFSET = 1 THEN PRINT "+";
        COLOR 15
        LOCATE 25, 11
        IF Sflag = 0 THEN PRINT "ccw prog "; : GOTO 401
        IF Sflag = 4 THEN PRINT "ccw retro"; : GOTO 401
        IF Sflag = 1 THEN PRINT "MAN      "; : GOTO 401
        IF Sflag = 2 THEN PRINT "app targ "; : GOTO 401
        IF Sflag = 5 THEN PRINT "pro Vtrg "; : GOTO 401
        IF Sflag = 6 THEN PRINT "retr Vtrg"; : GOTO 401
        IF Sflag = 7 THEN PRINT "hold Atrg"; : GOTO 401
        IF Sflag = 3 THEN PRINT "deprt ref";
401     COLOR 8
        IF Aflag = 0 THEN COLOR 10 ELSE COLOR 7
        LOCATE 22, 2: PRINT "center "; : LOCATE 22, 10: COLOR 15: PRINT " "; Znme$(cen); " ";
        IF Aflag = 1 THEN COLOR 10 ELSE COLOR 7
        LOCATE 23, 2: PRINT "target "; : LOCATE 23, 10: COLOR 15: PRINT " "; Znme$(targ); " ";
        IF Aflag = 2 THEN COLOR 10 ELSE COLOR 7
        LOCATE 24, 2: PRINT "ref    "; : LOCATE 24, 10: COLOR 15: PRINT " "; Znme$(ref); " ";
        COLOR 15
        LOCATE 9, 8: PRINT USING "#####.###"; ts;
        COLOR 7
        LOCATE 11, 2: PRINT "Fuel";
        LOCATE 14, 2: PRINT "Acc            ";
        LOCATE 15, 2: PRINT CHR$(233); " Hrt          ";
        LOCATE 16, 2: PRINT "Vcen          "; : IF ORref = 0 THEN PRINT "R";
        LOCATE 17, 2: PRINT "Vtan          "; : IF ORref = 0 THEN PRINT "R";
        LOCATE 18, 2: PRINT CHR$(233); Znme$(41 + PROJflag); "         ";
        IF PROJflag = 0 AND ORref = 0 THEN PRINT "R";  ELSE PRINT " ";
        LOCATE 19, 2: PRINT "Peri          "; : IF ORref = 0 THEN PRINT "R";
        LOCATE 20, 2: PRINT "Apo           "; : IF ORref = 0 THEN PRINT "R";
        COLOR 15
402     'IF dte = 1 THEN LOCATE 25, 60: PRINT USING "####"; year; : LOCATE 25, 66: PRINT USING "###"; day; hr; min; sec;
        RETURN



460     ON Aflag + 1 GOTO 461, 462, 463
461     IF cen = 40 THEN cen = 38
        IF cen - 1 = 36 AND MODULEflag = 0 THEN cen = 36
        IF cen - 1 < 0 THEN cen = 41
        cen = cen - 1
        cenXoff = 0
        cenYoff = 0
        GOSUB 405
        RETURN

462     IF targ - 1 = 28 THEN targ = 28
        IF targ - 1 = 36 AND MODULEflag = 0 THEN targ = 36
        IF targ - 1 < 0 THEN targ = 41
        IF targ = 40 THEN targ = 38 + ufo1 + ufo2
        targ = targ - 1
        GOSUB 400
        RETURN

463     IF ref - 1 = 28 THEN ref = 28
        IF ref - 1 = 36 AND MODULEflag = 0 THEN ref = 36
        IF ref - 1 < 0 THEN ref = 35
        ref = ref - 1
        GOSUB 400
        RETURN


465     ON Aflag + 1 GOTO 466, 467, 468
466     IF cen = 40 THEN cen = -1
        IF cen + 1 = 36 AND MODULEflag = 0 THEN cen = 36
        IF cen + 1 > 37 THEN cen = 39
        cen = cen + 1
        cenXoff = 0
        cenYoff = 0
        GOSUB 405
        RETURN

467     IF targ = 40 THEN targ = -1
        IF targ + 1 = 28 THEN targ = 28
        IF targ + 1 = 36 AND MODULEflag = 0 THEN targ = 36
        IF targ + 1 > 37 + ufo1 + ufo2 THEN targ = 39
        targ = targ + 1
        GOSUB 400
        RETURN

468     IF ref + 1 = 28 THEN ref = 28
        IF ref + 1 = 35 THEN ref = -1
        IF ref + 1 > 37 THEN ref = 36
        ref = ref + 1
        GOSUB 400
        RETURN


'# Create a file loading prompt. Curiously, `"Load File: "` is output first
'# at (10, 60), then followed by an input with a blank prompt.
'#
'# If the input is empty, jump to 703.
'#
'# If not, set `DEBUGflag` to 1 (TODO: find the use of `DEBUGflag`) and
'# jump to 701 (the code for reading and loading saves).
        'SUBROUTINE Restore data from file
700     LOCATE 10, 60: PRINT "Load File: "; : INPUT ; "", filename$
        IF filename$ = "" THEN 703
        DEBUGflag=1
        GOTO 701

'# Cover any content on row 10 from column 60 to 77 (78-80 are not covered)
'# and then jump to 700 to show a load file prompt.
702     LOCATE 10, 60: PRINT "                  ";
        GOTO 700

'# ## Start of data file reading
'# Open `$filename+".RND"` in "read-only" mode with filenumber #1 and record
'# length 1427.
'#
'# Make `inpSTR$` (possibly standing for "input string") a string of 1427
'# spaces. Read the first (at most) 1427 bytes into `inpSTR$`. Close file #1.
'#
'# *Note*: based on information from the FreeBasic documentation, the behavior
'# of the below when the file has less than 1427 bytes is unclear.
701     OPEN "R", #1, filename$+".RND", 1427
        inpSTR$=SPACE$(1427)
        GET #1, 1, inpSTR$
        CLOSE #1

'# If the length of `inpSTR$` is not 1427, output `filename$;" is unusable" at
'# (11,60) and jump to `702`
'#
'# Note that string functions use 1-based indexing.
'#
'# `chkCHAR1` and `chkCHAR2` ("chkCHAR"possibly standing for "check character"
'# are respectively the first and last (1427th in 1-based indexing) characters
'# of `inpSTR$`. `ORBITversion$` is the part of `inpSTR$` from char 2 to 8
'# (1-based and both inclusive).
'#
'# If either `chkCHAR1$` and `chkCHAR2$` are not the same or `ORBITversion` is
'# not equal to "ORBIT5S", output `filename$;" is unusable"` at (11,60) and
'# jump to 702.

        IF LEN(inpSTR$) <> 1427 THEN LOCATE 11,60:PRINT filename$;" is unusable";:GOTO 702
        chkCHAR1$=LEFT$(inpSTR$,1)
        chkCHAR2$=RIGHT$(inpSTR$,1)
        ORBITversion$=MID$(inpSTR$, 2, 7)
        IF chkCHAR1$<>chkCHAR2$ THEN LOCATE 11,60:PRINT filename$;" is unusable";:GOTO 702
        IF ORBITversion$<>"ORBIT5S" THEN LOCATE 11,60:PRINT filename$;" is unusable";:GOTO 702

'# **Summary**; The initialization process is as follows. First a prompt is
'# shown asking the user to enter a file name to open. If this file exists and
'# is valid, the data is loaded in, and the program continues with this file.
'# If nothing is entered, the program tries to load `OSBACKUP.RND` and
'# continue with it. If an broken file is entered, or if the file entered does
'# not exist (including the case where nothing is entered and `OSBACKUP.RND`
'# is loaded by default), a different prompt will show up asking the user to
'# enter a valid save file name. The prompt will not go away until a valid
'# file is loaded. If nothing is entered at this prompt and the user simply
'# presses `Enter`, a save file will not be loaded and a fresh simulation will
'# be created based on data loaded from `starsr` at the beginning of the
'# program.

'# `k` serves as a sort of pointer for reading the `inpSTR$` data string. It
'# starts from byte 17. TODO: find what bytes 9-16 are for.
'#
'# The following is a list of variables, their format (as stored in `inpStr$`,
'# descriptions (TODO), and corresponding byte positions in the data contained
'# by `inpSTR$` in 1-based indexes.
'#
'# Note that `integer` is 16 bit regardless of environment in QBasic. `long`
'# is 32 bits
        k=2+15

'# - `eng`: `single`, bytes `17-20`
        eng = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `vflag`: `integer`, bytes `21-22`
        vflag = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `Aflag`: `integer`, bytes `23-24`
        Aflag = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `Sflag`: `integer`, bytes `25-26`
        Sflag = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `Are`: `double`, bytes `27-34`
        Are = CVD(MID$(inpSTR$,k,8)):k=k+8

'# - `mag`: `double`, bytes `35-42`
        mag = CVD(MID$(inpSTR$,k,8)):k=k+8

'# - `Sangle`: `single`, bytes `43-46`
        Sangle = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `cen`: `integer`, bytes `47-48`
        cen = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `targ`: `integer`, bytes `49-50`. The ID of the target object.
        targ = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `ref`: `integer`, bytes `51-52`. The ID of the reference object.
        ref = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `trail`: `integer`, bytes `53-54`
        trail=CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `Cdh`: `single`, bytes `55-58`
        Cdh = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `SRB`: `single`, bytes `59-62`
        SRB = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `tr`: `integer`, bytes `63-64`. As far as can be deduced from the
'#   executable, `tr` is a flag, that when set to 1, makes objects leave
'#   colored trails in their display color. Appears to override the effects
'#   of `trail`, which leaves gray traces (but may only be because `tr` is
'#   painted after `trail`, TODO: confirm).
        tr = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `dte`: `integer`, bytes `65-66`
        dte = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `ts`: `double`, bytes `67-74`
        ts = CVD(MID$(inpSTR$,k,8)):k=k+8

'# - `OLDts`: `double`, bytes `75-82`
        OLDts = CVD(MID$(inpSTR$,k,8)):k=k+8

'# - `vernP!`: `single`, bytes `83-86`
        vernP! = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `Eflag`: `integer`, bytes `87-88`
        Eflag = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `year`: `integer`, bytes `89-90`
        year = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `day`: `integer`, bytes `91-92`
        day = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `hr`: `integer`, bytes `93-94`
        hr = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `min`: `integer`, bytes `95-96`
        min = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `sec`: `double`, bytes `97-104`
        sec = CVD(MID$(inpSTR$,k,8)):k=k+8

'# - `AYSEangle`: `single`, bytes `105-108`
        AYSEangle = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `AYSEscrape`: `integer`, bytes `109-110`
        AYSEscrape = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `Ztel(15)`: `single`, bytes `111-114`
        Ztel(15) = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `Ztel(16)`: `single`, bytes `115-118`
        Ztel(16) = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `HABrotate`: `single`, bytes `119-122`
        HABrotate = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `AYSE`: `integer`, bytes `123-124`
        AYSE = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `Ztel(9)`: `single`, bytes `125-128`
        Ztel(9) = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `MODULEflag`: `integer`, bytes `129-130`
        MODULEflag = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `AYSEdist`: `single`, bytes `131-134`: Distance to "Habitat " to
'#   "AYSE    "
        AYSEdist = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `OCESSdist`: `single`, bytes `135-138`: Distance from "Habitat " to
'#   "OCESS   "
        OCESSdist = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `explosion`: `integer`, bytes `139-140`
        explosion = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `explosion1`: `integer`, bytes `141-142`
        explosion1 = CVI(MID$(inpSTR$,k,2)):k=k+2

'# - `Ztel(1)`: `single`, bytes `143-146`
        Ztel(1) = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `Ztel(2)`: `single`, bytes `147-150`
        Ztel(2) = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `NAVmalf`: `long`, bytes `151-154`
        NAVmalf = CVL(MID$(inpSTR$,k,4)):k=k+4

'# - `Ztel(14)`: `single`, bytes `155-158`
        Ztel(14) = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `LONGtarg`: `single`, bytes `159-162`
        LONGtarg = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `Pr`: `single`, bytes `163-166`
        Pr = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `Agrav`: `single`, bytes `167-170`
        Agrav = CVS(MID$(inpSTR$,k,4)):k=k+4

'# 39 32-byte blocks of data are read into `Px`, `Py`, `Vx`, and `Vy`,
'# beginning with index of 1 each. This covers bytes `171-1418`.
'#
'# In each iteration, 4 doubles are read into `Px(i, 3)`, `Py(i, 3)`, `Vx(i)`,
'# `Vy(i)` respectively in that order.
        FOR i = 1 TO 39
            Px(i, 3) = CVD(MID$(inpSTR$,k,8)):k=k+8
            Py(i, 3) = CVD(MID$(inpSTR$,k,8)):k=k+8
            Vx(i) = CVD(MID$(inpSTR$,k,8)):k=k+8
            Vy(i) = CVD(MID$(inpSTR$,k,8)):k=k+8
        NEXT i

'# Two more variables are read:

'# - `fuel`: `single`, bytes `1419-1422`. The amount of fuel in the Habitat
        fuel = CVS(MID$(inpSTR$,k,4)):k=k+4

'# - `AYSEfuel`: `single`, bytes `1423-1426`
        AYSEfuel = CVS(MID$(inpSTR$,k,4)):k=k+4

'# The last byte (byte 1427) is a check byte (`chkCHAR2$`, see above) and is
'# not used.
'#
'# ## End of data file reading

'# ## Data processing after reading file.

'# Reset `TSindex` to 5. Find the index in `TSflagVECTOR` with a value
'# matching that of `ts` in the data file loaded and set `TSindex` to that
'# index. If no match is found, `TSindex` remains at 5.
        TSindex=5
        FOR i=1 TO 17
            IF TSflagVECTOR(i)=ts THEN TSindex=i:GOTO 713
        NEXT i

'# "OCESS   " is placed in a special hard-coded location relative to
'# "Earth   ". Upon file load, it is always placed about 6,288,118 m from the
'# center of Earth in the direction 45deg clockwise of right relative to the
'# center of "Earth   ". This code puts "OCESS   " at this fixed offset from
'# the center of "Earth   " and matches its velocity with that of "Earth   ".
713     Px(37, 3) = 4446370.8284487# + Px(3, 3): Py(37, 3) = 4446370.8284487# + Py(3, 3): Vx(37) = Vx(3): Vy(37) = Vy(3)

'# Zero out the position, velocity, and "cumulative net acceleration" of
'# "PROBE   " (ID 38) and "unknown " (ID 39). (TODO: find why this is needed)
        Px(38, 3) = 0: Py(38, 3) = 0: Vx(38) = 0: Vy(38) = 0: P(38, 1) = 0: P(38, 2) = 0
        Px(39, 3) = 0: Py(39, 3) = 0: Vx(39) = 0: Vy(39) = 0: P(39, 1) = 0: P(39, 2) = 0

'# TODO: understand
        tttt = TIMER + ts
        ufo1 = 0
        ufo2 = 0
        cenXoff = 0
        cenYoff = 0

'# The x and y coordinates of the center object are assigned to `cenX` and
'# `cenY` (likely standing for "center x" and "center y")
        cenX = Px(cen, 3)
        cenY = Py(cen, 3)

'# TODO: understand
703     explosion = 0
        explosion1 = 0
        GOSUB 405
        RETURN



        'SUBROUTINE save data to file
600     LOCATE 9, 60: PRINT "8 charaters a-z 0-9";
        LOCATE 10, 60: PRINT "Save File: "; : INPUT ; "", filename$
        IF filename$ = "" THEN GOSUB 405: RETURN
        OPEN "R", #1, filename$+".rnd",1427
        IF LOF(1) < 1 THEN 601
        LOCATE 11, 60: PRINT "File exists";
        LOCATE 12, 60: PRINT "overwrite? "; : INPUT ; "", z$
        IF UCASE$(LEFT$(z$, 1)) = "Y" THEN 601
        FOR i = 9 TO 12
            LOCATE i, 60: PRINT "                  ";
        NEXT i
        CLOSE #1
        GOTO 600
601     CLOSE #1
620     GOSUB 405
        GOTO 801


        'SUBROUTINE Timed back-up
800     filename$="OSBACKUP"
801     chkBYTE=chkBYTE+1
        IF chkBYTE>58 THEN chkBYTE=1
        outSTR$ = chr$(chkBYTE+64)
        outSTR$ = outSTR$ + "ORBIT5S        "
        outSTR$ = outSTR$ + mks$(eng)
        outSTR$ = outSTR$ + mki$(vflag)
        outSTR$ = outSTR$ + mki$(Aflag)
        outSTR$ = outSTR$ + mki$(Sflag)
        outSTR$ = outSTR$ + mkd$(Are)
        outSTR$ = outSTR$ + mkd$(mag)
        outSTR$ = outSTR$ + mks$(Sangle)
        outSTR$ = outSTR$ + mki$(cen)
        outSTR$ = outSTR$ + mki$(targ)
        outSTR$ = outSTR$ + mki$(ref)
        outSTR$ = outSTR$ + mki$(trail)
        outSTR$ = outSTR$ + mks$(Cdh)
        outSTR$ = outSTR$ + mks$(SRB)
        outSTR$ = outSTR$ + mki$(tr)
        outSTR$ = outSTR$ + mki$(dte)
        outSTR$ = outSTR$ + mkd$(ts)
        outSTR$ = outSTR$ + mkd$(OLDts)
        outSTR$ = outSTR$ + mks$(vernP!)
        outSTR$ = outSTR$ + mki$(Eflag)
        outSTR$ = outSTR$ + mki$(year)
        outSTR$ = outSTR$ + mki$(day)
        outSTR$ = outSTR$ + mki$(hr)
        outSTR$ = outSTR$ + mki$(min)
        outSTR$ = outSTR$ + mkd$(sec)
        outSTR$ = outSTR$ + mks$(AYSEangle)
        outSTR$ = outSTR$ + mki$(AYSEscrape)
        outSTR$ = outSTR$ + mks$(Ztel(15))
        outSTR$ = outSTR$ + mks$(Ztel(16))
        outSTR$ = outSTR$ + mks$(HABrotate)
        outSTR$ = outSTR$ + mki$(AYSE)
        outSTR$ = outSTR$ + mks$(Ztel(9))
        outSTR$ = outSTR$ + mki$(MODULEflag)
        outSTR$ = outSTR$ + mks$(AYSEdist)
        outSTR$ = outSTR$ + mks$(OCESSdist)
        outSTR$ = outSTR$ + mki$(explosion)
        outSTR$ = outSTR$ + mki$(explosion1)
        outSTR$ = outSTR$ + mks$(Ztel(1))
        outSTR$ = outSTR$ + mks$(Ztel(2))
        outSTR$ = outSTR$ + mkl$(NAVmalf)
        outSTR$ = outSTR$ + mks$(Ztel(14))
        outSTR$ = outSTR$ + mks$(LONGtarg)
        outSTR$ = outSTR$ + mks$(Pr)
        outSTR$ = outSTR$ + mks$(Agrav)
        FOR i = 1 TO 39
            outSTR$ = outSTR$ + mkd$(Px(i,3))
            outSTR$ = outSTR$ + mkd$(Py(i,3))
            outSTR$ = outSTR$ + mkd$(Vx(i))
            outSTR$ = outSTR$ + mkd$(Vy(i))
        NEXT i
        outSTR$ = outSTR$ + mks$(fuel)
        outSTR$ = outSTR$ + mks$(AYSEfuel)
        outSTR$ = outSTR$ + chr$(chkBYTE+64)
        OPEN "R", #1, filename$+".RND", 1427
        PUT #1, 1, outSTR$
        CLOSE #1

        k=1
813     OPEN "R", #1, "MST.RND", 26
        inpSTR$=space$(26)
        GET #1, 1, inpSTR$
        CLOSE #1
        IF len(inpSTR$) <> 26 THEN 811
        chkCHAR1$=left$(inpSTR$,1)
        chkCHAR2$=right$(inpSTR$,1)
        IF chkCHAR1$=chkCHAR2$ THEN 816
        k=k+1
        IF k<5 THEN 813 ELSE fileINwarn=1:GOTO 811
816     k=2
        MST# = CVD(mid$(inpSTR$,k,8)):k=k+8
        EST# = CVD(mid$(inpSTR$,k,8)):k=k+8
        LONGtarg = CVD(mid$(inpSTR$,k,8))/rad
        LONGtarg=LONGtarg+pi
        Ltx = (P(ref, 5) * SIN(LONGtarg))
        Lty = (P(ref, 5) * COS(LONGtarg))
        Ltr = ref

811     k=1
819     OPEN "R", #1, "ORBITSSE.RND", 210
        inpSTR$=SPACE$(210)
        GET #1, 1, inpSTR$
        CLOSE #1
        IF LEN(inpSTR$) <> 210 THEN LOCATE 25, 1:COLOR 12:PRINT "ENG telem";:GOTO 812
        chkCHAR1$=left$(inpSTR$,1)
        chkCHAR2$=right$(inpSTR$,1)
        IF chkCHAR1$=chkCHAR2$ THEN 818
        k=k+1
        IF k<3 THEN 819
        LOCATE 25, 1:COLOR 12:PRINT "ENG telem*";
        GOTO 812
818     k = 2
        FOR i = 1 TO 26
            Ztel(i)=CVD(mid$(inpSTR$,k,8)):k=k+8
        NEXT i
        RADAR = (2 AND Ztel(8))
        INS = 4 AND (Ztel(8))
        LOS = 8 AND (Ztel(8))
        Ztel(8) = (1 AND Ztel(8))
        IF (8 AND Ztel(26)) = 8 THEN 9100
        NAVmalf = Ztel(1)
        Ztel(1) = (2 AND Ztel(1)) / 2
        'Ztel(2) = engine force factor
        fuel = Ztel(3)  'HAB fuel mass
        AYSEfuel = Ztel(4)  'AYSE fuel mass
        'Ztel(5) = HAB explosion
        'Ztel(6) = AYSE explosion
        'Ztel(7) = Ztel7: Ztel7 = 0
        IF Ztel(7) = 2 AND MODULEflag = 0 THEN GOSUB 3200
        IF Ztel(7) = 1 AND MODULEflag > 0 THEN GOSUB 3200
        IF Ztel(8) = 1 THEN ts = .125:TSindex=4
        'Ztel(9) = rshield

        IF (1 AND Ztel(10)) = 1 AND vernP! < 100 THEN vernP! = vernP! + 25 * ts
        IF vernP! > 120 THEN vernP! = 120
        IF vernP! < 0 THEN vernP! = 0
        vernCNT = (16 AND Ztel(10)) / 16
        IF (2 AND Ztel(10)) = 2 THEN Cdh = .0006 ELSE Cdh = .0002
        IF (4 AND Ztel(10)) = 4 AND SRBtimer < 1 THEN SRBtimer = 220
        Zx = (224 AND Ztel(10))
        IF Zx > 0 THEN HABrotMALF = (Zx - 128) / 32 ELSE HABrotMALF = 0
        Zx = 7680 AND Ztel(10)

        IF explosion > 0 THEN explosion = explosion - 1
        IF explosion1 > 0 THEN explosion1 = explosion1 - 1
        IF Ztel(1) = 1 THEN Sflag = 1
        IF DISPflag = 0 THEN COLOR 7 + (5 * Ztel(1)): LOCATE 25, 2: PRINT "NAVmode";
        COLOR 15
        IF ufoTIMER > 0 THEN ufoTIMER = ufoTIMER - 1: GOTO 812

        IF Ztel(17) = 2 THEN ufo1 = 0: Px(38, 3) = 0: Py(38, 3) = 0: ufo2 = 0: Px(39, 3) = 0: Py(39, 3) = 0
        IF Ztel(23) >= 0 THEN 815
            ufoTIMER = 10
            ufo1 = 0
            ufo2 = 0
            Zt = ABS(Ztel(23))
            Px(Zt, 3) = Px(38, 3)
            Py(Zt, 3) = Py(38, 3)
            Vx(Zt) = Vx(38)
            Vy(Zt) = Vy(38)
            P(Zt, 1) = P(38, 1)
            P(Zt, 2) = P(38, 2)
            Px(38, 3) = 0
            Py(38, 3) = 0
            Px(39, 3) = 0
            Py(39, 3) = 0
            CONflag2 = 0
            GOTO 812
815     IF Ztel(23) < 38 AND ufo2 = 0 AND ufo1 = 1 THEN GOSUB 7100
        IF Ztel(23) = 39 AND ufo2 = 1 THEN explCENTER = 39: GOSUB 6000
812     COLOR 15
        RETURN


'# Subroutine for exioting the  program. Create an input with prompt
'# `End Program ` at (10, 60). If the  input is `y` (case-insensitive), end
'# the program. Otherwise, cover the prompt and any input with spaces (the
'# last two characters on the right side are not covered due to there only
'# being 19 spaces in the "cover" string and not 21) and return.
        'Confirm end program
900     LOCATE 10, 60: INPUT ; "End Program "; z$
        IF UCASE$(z$) = "Y" THEN END
        LOCATE 10, 60: PRINT "                   ";
        RETURN

        'Orbit Projection
3000    GOSUB 3005
        GOSUB 3008
        GOSUB 3006
        L# = 2 * orbA
        IF ecc < 1 THEN L# = (1 - (ecc ^ 2)) * orbA
        IF ecc > 1 THEN L# = ((ecc ^ 2) - 1) * orbA
        difX = Px(ORrefOBJ, 3) - Px(28, 3)
        difY = Py(ORrefOBJ, 3) - Py(28, 3)
        GOSUB 5000
        r# = SQR((difX ^ 2) + (difY ^ 2))
        term# = (L# / r#) - 1
        IF ABS(ecc) < .0000001# THEN ecc = SGN(ecc) * .0000001#
        term# = term# / ecc
        IF ABS(term#) > 1 THEN num# = 0 ELSE num# = eccFLAG * SQR(1 - (term# ^ 2))
        dem# = 1 - term#
        difA# = 2 * ATN(num# / dem#)
        difA# = 3.1415926# - difA# - angle#
        stp = .1
        lim1 = -180: lim2 = 180
        IF ecc < 1 THEN lim1 = 0: lim2 = 179
        IF ecc > 1 THEN GOSUB 3010
        FRAMEflag = 0
3003    FOR i = lim1 TO lim2 STEP stp
            angle# = i / 57.29578
            d# = 1 + (ecc * COS(angle#))
            r# = L# / d#
            difX# = (r# * SIN(angle# - difA#)) + Px(ORrefOBJ, 3)
            difY# = (r# * COS(angle# - difA#)) + Py(ORrefOBJ, 3)
            IF ecc < 1 THEN 3018
            IF ABS(i - lim1) < stp THEN difX1 = difX#: difY1 = difY#
            IF ABS(i - lim2) < stp THEN difX2 = difX#: difY2 = difY#
            IF ABS(i - 0) < stp THEN difX3 = difX#: difY3 = difY#
            GOTO 3019
3018        IF ABS(i - 180) < stp THEN difX1 = difX#: difY1 = difY#
            IF ABS(i - lim2) < stp THEN difX3 = difX#: difY3 = difY#
3019        difX# = 300 + ((difX# - cenX) * mag / AU)
            difY# = 220 + ((difY# - cenY) * mag / AU)
            IF ABS(300 - difX#) > 400 OR ABS(220 - difY#) > 300 THEN FRAMEflag = 0: GOTO 3002
            IF FRAMEflag = 0 THEN PSET (difX#, difY#), 15 ELSE LINE -(difX#, difY#), 15
            PSET (difX#, difY#), 15
            FRAMEflag = 1
3002    NEXT i
        IF ecc < 1 AND lim2 = 179 THEN lim1 = 179: lim2 = 181: stp = .001: GOTO 3003
        IF ecc < 1 AND lim2 = 181 THEN lim1 = 181: lim2 = 359.9: stp = .1: GOTO 3003
        GOSUB 3020
        RETURN

3005    IF ORref = 1 THEN ORrefD = Dtarg: ORrefOBJ = targ: GOTO 3009
        difX = Vx(ref) - Vx(28)
        difY = Vy(ref) - Vy(28)
        GOSUB 5000
        ORrefOBJ = ref
        VangleDIFF = Aref - angle
        ORrefD = Dref
3009    RETURN

3006    orbEk# = (((Vx(28) - Vx(ORrefOBJ)) ^ 2 + (Vy(28) - Vy(ORrefOBJ)) ^ 2)) / 2
        orbEp# = -1 * G * P(ORrefOBJ, 4) / ORrefD
        orbD# = G * P(ORrefOBJ, 4)
        IF orbD# = 0 THEN orbD# = G * 1
        L2# = (ORrefD * Vtan) ^ 2
        orbE# = orbEk# + orbEp#
        term2# = 2 * orbE# * L2# / (orbD# * orbD#)
        ecc = SQR(1 + term2#)
        IF orbE# = 0 THEN LOCATE 20, 7: PRINT SPACE$(9); : LOCATE 19, 7: PRINT SPACE$(9); : GOTO 3007
        orbA = orbD# / ABS(2 * orbE#)
        PROJmax = orbA * (1 + ecc)
        PROJmin = orbA * (1 - ecc)
        IF ecc = 1 THEN PROJmin = orbA
        IF ecc > 1 THEN PROJmin = orbA * (ecc - 1)
        IF DISPflag = 1 THEN RETURN
        IF targDISP = 0 THEN RETURN
        IF (8 AND NAVmalf) = 8 THEN RETURN
        PROJmin = (PROJmin - P(ORrefOBJ, 5)) / 1000
        PROJmax = (PROJmax - P(ORrefOBJ, 5)) / 1000
        LOCATE 19, 7
        IF ABS(PROJmin) > 899999 THEN PRINT USING "##.##^^^^"; PROJmin;  ELSE PRINT USING "######.##"; PROJmin;
        LOCATE 20, 7
        IF ecc >= 1 THEN PRINT "  -------"; : GOTO 3007
        IF ABS(PROJmax) > 899999 THEN PRINT USING "##.##^^^^"; PROJmax;  ELSE PRINT USING "######.##"; PROJmax;
3007    RETURN

3008    Vcen = SQR(((Vx(28) - Vx(ORrefOBJ)) ^ 2 + (Vy(28) - Vy(ORrefOBJ)) ^ 2)) * -1 * COS(VangleDIFF)
        Vtan = SQR(((Vx(28) - Vx(ORrefOBJ)) ^ 2 + (Vy(28) - Vy(ORrefOBJ)) ^ 2)) * (SIN(VangleDIFF))
        IF DISPflag = 1 THEN RETURN
        IF targDISP = 0 THEN RETURN
        IF (16384 AND NAVmalf) = 16384 THEN RETURN
        LOCATE 16, 7
        IF ABS(Vcen) > 99999 THEN PRINT USING "##.##^^^^"; Vcen;  ELSE PRINT USING "######.##"; Vcen;
        LOCATE 17, 7
        IF ABS(Vtan) > 99999 THEN PRINT USING "##.##^^^^"; Vtan;  ELSE PRINT USING "######.##"; Vtan;
        eccFLAG = SGN(Vcen) * SGN(Vtan)
        IF Vcen = 0 THEN eccFLAG = SGN(Vtan)
        IF Vtan = 0 THEN eccFLAG = SGN(Vcen)
        RETURN

3010    term# = 1 / ecc
        dem# = 1 + SQR(1 - (term# ^ 2))
        term# = term# / dem#
        term# = (2 * ATN(term#) * 57.29578) + 90
        lim1 = -1 * term#
        lim2 = term#
        RETURN

3020    IF targ = ref THEN RETURN
        difX = difX1 - Px(ref, 3)
        difY = difY1 - Py(ref, 3)
        r = SQR((difY ^ 2) + (difX ^ 2))
        GOSUB 5000
        AtoAPOAPSIS = ABS(angle - Atr)
        IF AtoAPOAPSIS > 3.1415926535# THEN AtoAPOAPSIS = 6.283185307# - AtoAPOAPSIS
        LOCATE 27, 2
        PRINT CHR$(233); " tRa";
        LOCATE 27, 10
        PRINT USING "###"; AtoAPOAPSIS * RAD; : PRINT CHR$(248);
        IF ecc < 1 THEN 3021
        difX = difX2 - Px(ref, 3)
        difY = difY2 - Py(ref, 3)
        r = SQR((difY ^ 2) + (difX ^ 2))
        GOSUB 5000
        AtoAPOAPSIS = ABS(angle - Atr)
        IF AtoAPOAPSIS > 3.1415926535# THEN AtoAPOAPSIS = 6.283185307# - AtoAPOAPSIS
        PRINT USING "#####"; AtoAPOAPSIS * RAD; : PRINT CHR$(248);
3021    difX = difX3 - Px(ref, 3)
        difY = difY3 - Py(ref, 3)
        r = SQR((difY ^ 2) + (difX ^ 2))
        GOSUB 5000
        AtoAPOAPSIS = ABS(angle - Atr)
        IF AtoAPOAPSIS > 3.1415926535# THEN AtoAPOAPSIS = 6.283185307# - AtoAPOAPSIS
        LOCATE 28, 2
        PRINT CHR$(233); " tRp";
        LOCATE 28, 10
        PRINT USING "###"; AtoAPOAPSIS * RAD; : PRINT CHR$(248);
        RETURN
        '****************************************************

        'Restore orbital altitude of ISS after large time step
3100    difX = Px(3, 3) - Px(35, 3)
        difY = Py(3, 3) - Py(35, 3)
        GOSUB 5000
        Px(35, 3) = Px(3, 3) + ((P(3, 5) + 365000) * SIN(angle))
        Py(35, 3) = Py(3, 3) + ((P(3, 5) + 365000) * COS(angle))
        Vx(35) = Vx(3) + (SIN(angle + 1.570796) * SQR(G * P(3, 4) / (P(3, 5) + 365000)))
        Vy(35) = Vy(3) + (COS(angle + 1.570796) * SQR(G * P(3, 4) / (P(3, 5) + 365000)))
        RETURN

3200    'LOCATE 23, 40: PRINT CONflag;
        IF CONflag = 0 THEN 3299
        IF MODULEflag = 0 THEN 3210
        difX = Px(28, 3) - Px(36, 3)
        difY = Py(28, 3) - Py(36, 3)
        r = SQR((difY ^ 2) + (difX ^ 2))
        IF r > 90 THEN 3299
        IF targ = 36 THEN targ = CONtarg
        IF ref = 36 THEN ref = CONtarg
        IF cen = 36 THEN cen = 28
        MODULEflag = 0
        GOSUB 405
        GOTO 3299

3210    Px(36, 3) = Px(28, 3) - ((80 - P(36, 5)) * SIN(Sangle))
        Py(36, 3) = Py(28, 3) - ((80 - P(36, 5)) * COS(Sangle))
        P(36, 1) = Px(36, 3) - Px(CONtarg, 3)
        P(36, 2) = Py(36, 3) - Py(CONtarg, 3)
        MODULEflag = CONtarg
        Vx(36) = Vx(MODULEflag)
        Vy(36) = Vy(MODULEflag)

3299    RETURN


'# An implementation of something similar to `atan2`. Calculates the angle
'# from the first object in a pair to the second based on `difX` and `difY`.
'#
'# The resulting angle is the angle (counterclockwise) of the second object
'# relative to the first, in radians, with the negative y direction (upward on
'# the display, TODO: confirm) being the direction for which the angle equals
'# 0. The value of `angle` is in the interval [0, 2pi).
'#
'# If `difX` and `difY` are both 0, the resulting `angle` is 1.5 pi.

5000    IF difY = 0 THEN IF difX < 0 THEN angle = .5 * 3.1415926535# ELSE angle = 1.5 * 3.1415926535# ELSE angle = ATN(difX / difY)
        IF difY > 0 THEN angle = angle + 3.1415926535#
        IF difX > 0 AND difY < 0 THEN angle = angle + 6.283185307#
        RETURN


        'Explosions
6000    Xexpl = 300 + (Px(explCENTER, 3) - cenX) * mag / AU
        Yexpl = 220 + (Py(explCENTER, 3) - cenY) * mag / AU
        'PLAY "ML L25 GD MB"
        IF ABS(Xexpl) > 1000 OR ABS(Yexpl) > 1000 THEN 6001
        FOR Xj = 0 TO 14
            FOR Xi = 1 TO (49 - (2 * Xj))
                explANGLE = RND * 2 * 3.1415926535#
                Xexpl1 = Xexpl + (SIN(explANGLE) * Xj * 2)
                Yexpl1 = Yexpl + (COS(explANGLE) * Xj * 2)

                PRESET (Xexpl1, Yexpl1), 14
            NEXT Xi
            FOR Xi = 1 TO 100000: NEXT Xi
        NEXT Xj
        FOR Xj = 1 TO 56
            CIRCLE (Xexpl, Yexpl), Xj / 2, 0
            LINE (Xexpl - Xj / 3, Yexpl - Xj / 3)-(Xexpl + Xj / 3, Yexpl + Xj / 3), 0, BF
        NEXT Xj
6001    'LOCATE 1, 35
        IF i < 0 THEN i = 0
        IF i > 39 THEN i = 0
        IF explCENTER = 39 THEN ufo2 = 0: Px(39, 3) = 0: Py(39, 3) = 0
        IF explCENTER = 39 AND B(i, 0) <> 28 THEN ufo1 = 0: Px(38, 3) = 0: Py(38, 3) = 0
        IF explCENTER = 39 AND B(i, 0) = 28 THEN CONflag = 1: CONtarg = B(0, i): Dcon = r: Acon = angle: CONacc = a
        IF explCENTER = 38 AND B(i, 0) = 28 THEN CONflag = 1: CONtarg = B(0, i): Dcon = r: Acon = angle: CONacc = a
        IF explCENTER = 38 THEN ufo1 = 0: Px(38, 3) = 0: Py(38, 3) = 0
        IF explCENTER = 28 OR explCENTER = 32 THEN ts = .25:TSindex=5
        IF explCENTER = 28 THEN explosion = 12: Ztel(2) = 0: Ztel(1) = 0: LOCATE 25, 2: PRINT "NAVmode"; : LOCATE 25, 11: PRINT "manual   ";
        IF explCENTER = 32 THEN explosion1 = 12
        COLOR 15
        LOCATE 8, 10: PRINT USING "##.###"; ts;
        RETURN



7000    BEEP
        r = 100 + P(Ztel(18), 5)

        Vx(38) = Vx(Ztel(18)) + (200 * SIN(Sangle + 3.14159))
        Vy(38) = Vy(Ztel(18)) + (200 * COS(Sangle + 3.14159))

        Px(38, 3) = Px(Ztel(18), 3) + (r * SIN(Sangle + 3.14159))
        Py(38, 3) = Py(Ztel(18), 3) + (r * COS(Sangle + 3.14159))
        ufo1 = 1
        z$ = ""
        RETURN

7100    Px(39, 3) = Px(38, 3)
        Py(39, 3) = Py(38, 3)
        difX = Px(39, 3) - Px(Ztel(23), 3)
        difY = Py(39, 3) - Py(Ztel(23), 3)
        r = SQR((difY ^ 2) + (difX ^ 2))
        GOSUB 5000
        Vt = r / 10000
        IF Vt > 1000 THEN 7110
        Vt = CINT(Vt)
        V = r / Vt
        Vx(39) = Vx(Ztel(23)) + (V * SIN(angle))
        Vy(39) = Vy(Ztel(23)) + (V * COS(angle))
        ufo2 = 1
        Px(39, 1) = 4000
7110    RETURN


7200    difX = Px(38, 3) - Px(Ztel(18), 3)
        difY = Py(38, 3) - Py(Ztel(18), 3)
        GOSUB 5000
        IF Ztel(21) = 0 THEN angle = angle - (90 / RAD)
        IF Ztel(21) = 1 THEN angle = angle + (90 / RAD)
        IF Ztel(21) = 2 THEN angle = angle + (180 / RAD)
        Vx(38) = Vx(38) + (Ztel(22) * ts * SIN(angle))
        Vy(38) = Vy(38) + (Ztel(22) * ts * COS(angle))
        RETURN

'# Draw the background stars. TODO: confirm and elaborate
8000    FOR i = 1 TO 3021
            IF ABS(300 + (Pz(i, 1) - cenX) * mag / AU) > 1000 THEN 8001
            IF ABS(220 + (Pz(i, 2) - cenY) * mag / AU) > 1000 THEN 8001
            PSET (300 + (Pz(i, 1) - cenX) * mag / AU, 220 + (Pz(i, 2) - cenY) * mag * 1 / AU), Pz(i, 0)
8001    NEXT i
        RETURN


8100    time# = (year * 31536000#) + (day * 86400#) + (hr * 3600#) + (min * 60#) + sec
        IF dte = 2 THEN etime# = MST# ELSE etime# = EST#
        IF time# > etime# THEN dtime# = time# - etime#: TIMEsgn = 1 ELSE dtime# = etime# - time#: TIMEsgn = -1

        IF TIMEsgn = -1 AND dtime# < 121 THEN ts = .125:TSindex=4
        dyr# = INT(dtime# / 31536000#)
        dday# = dtime# - (dyr# * 31536000#)
        dday# = INT(dday# / 86400#)
        dhr# = dtime# - (dyr# * 31536000#) - (dday# * 86400#)
        dhr# = INT(dhr# / 3600#)
        dmin# = dtime# - (dyr# * 31536000#) - (dday# * 86400#) - (dhr# * 3600#)
        dmin# = INT(dmin# / 60#)
        dsec# = dtime# - (dyr# * 31536000#) - (dday# * 86400#) - (dhr# * 3600#) - (dmin# * 60#)
        LOCATE 25, 58
        IF dte = 2 THEN PRINT "M:";  ELSE PRINT "E:";
        IF TIMEsgn = -1 THEN PRINT "-";  ELSE PRINT " ";
        LOCATE 25, 61: PRINT USING "####_ "; dyr#; : LOCATE 25, 66: PRINT USING "###"; dday#; dhr#; dmin#;
        IF ts < 60 THEN LOCATE 25, 75: PRINT USING "###"; dsec#;

        RETURN

'# Some sort of special handling used only for "Mars    ". TODO: elaborate
8500    z$="  "
        x1 = 640 * ((ELEVangle*RAD) + 59.25+180) / 360
        IF x1 > 640 THEN x1 = x1 - 640
        y1 = 50 * SIN((x1 - 174.85) / 101.859164#)
        lngW = 11520*x1/640
        latW = 5760 *(y1+160)/320
        lng = INT(lngW)
        lat = INT(latW)

                ja=1+(lng)+(lat*11520)
                GET #3, ja, z$
                h1=CVI(z$)

                ja=1+(lng)+((lat+1)*11520)
                GET #3, ja, z$
                h2=CVI(z$)


                IF LNG=11519 THEN ja=1+(lat*11520)  ELSE ja=1+(lng+1)+(lat*11520)
                GET #3, ja, z$
                h3=CVI(z$)

                IF LNG=11519 THEN ja=1+((lat+1)*11520)  ELSE ja=1+(lng+1)+((lat+1)*11520)
                GET #3, ja, z$
                h4=CVI(z$)

                        LATdel=latW-lat
                        LNDdel=lngW-lng
                        h=h1*(1-LATdel)*(1-LNGdel)
                        h=h+(h2*(LATdel)*(1-LNGdel))
                        h=h+(h3*(1-LATdel)*(LNGdel))
                        h=h+(h4*(LATdel)*(LNGdel))
                RETURN

'# Error handler. Output at (1, 30) `'stars' file is missing or incomplete` if
'# the line number of the line where the error occurred (the 1-based source
'# code line number, not the BASIC "label" line number) is 91.
'#
'# The line number of the line where `starsr` is first opened in the
'# un-annotated version of this file is line 8 (but it does have a "label" for
'# 91) (note that the source line  number has shifted due to the extra
'# annotations), so even if `starsr` fails to open, this message is not shown
'# (likely unintended behavior).
9000    LOCATE 1, 30
        IF ERL = 91 THEN CLOSE #1: CLS : PRINT "'stars' file is missing or incomplete"

'# Output the error number and error line number (as described above).
        PRINT ERR, ERL

'# The `INPUT$(1)` reads 1 character from the console (blocking). This is used
'# to implement a sort of "press any key to continue." After any key is
'# is pressed, the program ends.
        z$ = INPUT$(1)
        END


9100    OPEN "R", #1, "ORBITSSE.RND", 210
        inpSTR$=SPACE$(210)
        GET #1, 1, inpSTR$
        MID$(inpSTR$,202,8)=MKD$(0)
        PUT #1, 1, inpSTR$
        CLOSE #1
        OPEN "O", #1, "orbitstr.txt"
        IF Ztel(26) = 8 THEN PRINT #1, "OSBACKUP"
        IF Ztel(26) = 24 THEN PRINT #1, "RESTART"
        CLOSE #1
        RUN "orbit5va"

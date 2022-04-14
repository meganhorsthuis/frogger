#####################################################################
#
# CSC258H5S Winter 2022 Assembly Final Project
# University of Toronto, St. George
#
# Student: Megan Horsthuis
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
#####################################################################

.data
	displayAddress: .word 0x10008000
	frogAddress: .word 0x00000000
	speed: .word  0x00000000

	logArray1: .space 512
	logArray2: .space 512
	carArray1: .space 512
	carArray2: .space 512

	endclr: .word 0x00a86b
	grassclr: .word 0x00a572
	midclr: .word 0x00a574
	frogclr: .word 0x98fb98
	brokenfrogclr: .word 0x2f4f4f
	waterclr: .word 0x95c8d8
	roadclr: .word 0xdbd7d2
	carclr: .word 0xf77fbe
	logclr: .word 0xbe7e3e
	heartclr: .word 0xc71585
	gameoverclr: .word 0x191970
	xclr: .word 0xff0000
	oclr: .word 0x32cd32

	direction: .word 0:1
	lives: .word 3:1


.text

Start:
 	# only runs the first time

	# set frog location
	lw $t0, displayAddress
	addi $t0, $t0, 3640
	sw $t0, frogAddress

	# draw the first log
	la $t0, logArray1
	addi $a0, $zero, 4
	addi $a1, $zero, 8
	add $a2, $zero, $t0
	addi $a3, $zero, 1 # load 1 as colour to indicate where object is
	jal DrawRectangle

	# draw the second log
	la $t0, logArray1
	addi $a2, $t0, 64
	jal DrawRectangle

	# draw the third log
	la $t0, logArray2
	addi $a2, $t0, 32
	jal DrawRectangle

	# draw the fourth log
	la $t0, logArray2
	addi $a2, $t0, 96
	jal DrawRectangle

	# draw the first car
	la $t0, carArray1
	addi $t4, $zero, 0 # 0 indicates car is facing left
	addi $a2, $t0, 32
	jal DrawCar

	# draw the second car
	la $t0, carArray1
	addi $t4, $zero, 0 # 0 indicates car is facing left
	addi $a2, $t0, 96
	jal DrawCar

	# draw the third car
	la $t0, carArray2
	addi $t4, $zero, 1 # 1 indicates car is facing right
	add $a2, $zero, $t0
	jal DrawCar

	# draw the fourth car
	la $t0, carArray2
	addi $t4, $zero, 1 # 1 indicates car is facing right
	addi $a2, $t0, 64
	jal DrawCar

	lw $t0, lives
	addi $t0, $zero, 3
	sw $t0, lives # initialize lives to 3

	jal DrawBackground
	jal DrawDynamic
	jal DrawFroggie
	jal DrawHearts

	# set initial speed
	lw $t0, speed
	addi $t0, $zero, 1
	sw $t0, speed

	# set the counter to 0 initially
	addi $s0, $zero, 0


GameLoop:

	addi $v0, $zero, 32 # call to sleep
	addi $a0, $zero, 100 # set to 100 ms
	syscall

	lw $t2, speed
	add $t0, $zero, $t2 # slow down speed
	beq $s0, $t0, MoveObj # only shift all the obstacles if $t2 GameLoop iterations have occured
	addi $s0, $s0, 1 # increment counter

	lw $t1, 0xffff0000 # check for keyboard input
	beq $t1, 1, KeyboardInput # branch if a key was pressed
	jal CheckCollision  # if no key was pressed, check if we got hit
	j StayPut # jump to procedure if we were not hit and no key was pressed


KeyboardInput:

	lw $t3, 0xffff0004 # read the key press
	beq $t3, 0x77, MoveUp # if 'w' is pressed
	beq $t3, 0x61, MoveLeft # if 'a' is pressed
	beq $t3, 0x73, MoveDown # if 's' is pressed
	beq $t3, 0x64, MoveRight # if 'd' is pressed
	j StayPut # stay put if different key was pressed

	MoveUp:
		lw $t1, frogAddress
		addi $t3, $zero, -512
		add $t1, $t1, $t3 # set frog address to 4 units up
		sw $t1, frogAddress

		la $t1, direction
		addi $t2, $zero, 0
		sw $t2, ($t1) # set new frog direction

		j UpdateFrog


	MoveLeft:
		lw $t1, frogAddress
		li $t3, -16
		add $t1, $t1, $t3 # set frog address to 4 units left
		sw $t1, frogAddress

		la $t1, direction
		addi $t2, $zero, 1
		sw $t2, ($t1) # set new frog direction

		j UpdateFrog


	MoveDown:
		lw $t1, frogAddress
		li $t3, 512
		add $t1, $t1, $t3 # set frog address to 4 units down
		sw $t1, frogAddress

		la $t1, direction
		addi $t2, $zero, 2
		sw $t2, ($t1) # set new frog direction

		j UpdateFrog


	MoveRight:
		lw $t1, frogAddress
		li $t3, 16
		add $t1, $t1, $t3 # set frog address to 4 units right
		sw $t1, frogAddress

		la $t1, direction
		li $t2, 3
		sw $t2, ($t1)

		j UpdateFrog


	UpdateFrog:
		jal DrawBackground

		addi $sp, $sp, -4
		sw $ra, ($sp)
		jal DrawHearts
		lw $ra, ($sp)
		addi $sp, $sp, 4

		lw $t1, frogAddress
		lw $t2, ($t1)
		lw $t3, carclr
		lw $t4, waterclr
		lw $t5, endclr
		lw $t6, midclr

		beq $t2, $t3, FroggieDies # frog dies if it touches a car
		beq $t2, $t4, FroggieDies # frog dies if it touches water
		beq $t2, $t5, FroggieWins # frog wins if it touches the end grass
		beq $t2, $t6, UpdateSpeed # game gets faster if frog reaches middle grass

		j DrawUpdatedFrog


	UpdateSpeed:
		lw $t1, speed
		addi $t2, $zero, 1
		sw $t2, speed # increase speed
		j DrawUpdatedFrog


	StayPut:
		jal CheckCollision
		j DrawUpdatedFrog


	DrawUpdatedFrog:
		jal DrawDynamic
		jal DrawFroggie
		jal DrawHearts
		j GameLoop


	CheckCollision:
		lw $t0, frogAddress
		addi $t1, $t0, 140
		lw $t5, ($t1)

		lw $t3, carclr
		lw $t4, waterclr

		beq $t5, $t3, FroggieDies
		beq $t5, $t4, FroggieDies

		lw $t1, frogAddress
		addi $t2, $t1, 124
		lw $t5, ($t2)

		beq $t5, $t3, FroggieDies
		beq $t5, $t4, FroggieDies

		jr $ra


	FroggieDies:

		jal DrawBackground
		jal DrawDynamic
		jal DrawBrokenFroggie

		lw $t3, lives
		addi $t5, $t3, -1
		sw $t5, lives # update lives
		jal DrawHearts

		addi $v0, $zero, 32 # call to sleep
		addi $a0, $zero, 1000 # set to 1000 ms
		syscall

		lw $t5, lives
		addi $t4, $zero, 0
		beq $t5, $t4, GameOver # game over if we are out of lives

		lw $t1, displayAddress
		addi $t1, $t1, 3640
		sw $t1, frogAddress # reset frog address to the start location

		la $t1, direction
		addi $t2, $zero, 0
		sw $t2, ($t1) # reset the direction the frog is facing to the front

		lw $t1, speed
		addi $t2, $zero, 2
		sw $t2, speed # reset the speed

		j GameLoop


	FroggieWins:

		jal DrawFroggie
		jal DrawDynamic
		j Exit


DrawBrokenFroggie:

	lw $t0, frogAddress
	add $t1, $zero, $t0 # store frog address in $t1
	lw $t2, brokenfrogclr

	sw $t2, ($t1)
	sw $t2, 12($t1)
	addi $t1, $t1, 128
	sw $t2, 4($t1)
	sw $t2, 12($t1)
	addi $t1, $t1, 128
	sw $t2, 8($t1)
	addi $t1, $t1, 128
	sw $t2, ($t1)
	sw $t2, 8($t1)

	jr $ra


GameOver:

	lw $t1, displayAddress
	addi $t1, $t1, 3640
	sw $t1, frogAddress # reset frog address to the start location

	lw $t0, displayAddress
	lw $t4, gameoverclr
	addi $a0, $zero, 32
	addi $a1, $zero, 32
	add $a2, $zero, $t0
	add $a3, $zero, $t4
	jal DrawRectangle

	lw $t1, xclr # load colour of the X

	# draw X on screen
	addi $t3, $t0, 1552
	sw $t1, ($t3)
	sw $t1, 28($t3)
	addi $t3, $t3, 128
	sw $t1, 4($t3)
	sw $t1, 24($t3)
	addi $t3, $t3, 128
	sw $t1, 8($t3)
	sw $t1, 20($t3)
	addi $t3, $t3, 128
	sw $t1, 12($t3)
	sw $t1, 16($t3)
	addi $t3, $t3, 128
	sw $t1, 8($t3)
	sw $t1, 20($t3)
	addi $t3, $t3, 128
	sw $t1, 4($t3)
	sw $t1, 24($t3)
	addi $t3, $t3, 128
	sw $t1, ($t3)
	sw $t1, 28($t3)

	lw $t1, oclr # load colour of the O

	# draw O on screen
	addi $t3, $t0, 1616
	sw $t1, 12($t3)
	sw $t1, 16($t3)
	addi $t3, $t3, 128
	sw $t1, 8($t3)
	sw $t1, 20($t3)
	addi $t3, $t3, 128
	sw $t1, 4($t3)
	sw $t1, 24($t3)
	addi $t3, $t3, 128
	sw $t1, ($t3)
	sw $t1, 28($t3)
	addi $t3, $t3, 128
	sw $t1, ($t3)
	sw $t1, 28($t3)
	addi $t3, $t3, 128
	sw $t1, 4($t3)
	sw $t1, 24($t3)
	addi $t3, $t3, 128
	sw $t1, 8($t3)
	sw $t1, 20($t3)
	addi $t3, $t3, 128
	sw $t1, 12($t3)
	sw $t1, 16($t3)
	addi $t3, $t3, 128

	Keypress:
		lw $t1, 0xffff0000 # check for keyboard input
		beq $t1, 1, YesOrNo # branch if a key was pressed
		j Keypress

	YesOrNo:
		lw $t2, 0xffff0004
		beq $t2, 0x6f, Reset # reset if 'o' is pressed
		beq $t2, 0x78, Exit # exit if 'x' is pressed
		j Keypress

	Reset:
		addi $t1, $zero, 3
		sw $t1, lives # reset lives to 3

		la $t1, direction
		addi $t2, $zero, 0
		sw $t2, ($t1) # reset the direction the frog is facing to the front

		jal DrawBackground
		jal DrawHearts
		j GameLoop


DrawRectangle:

	# $a0: rectangle height
	# $a1: rectangle width
	# $a2: address of the rectangle's top left corner
	# $a3: colour address

	addi $t1, $zero, 32 # since a row has 128/4=32 units
	addi $t2, $zero, 4 # offset
	addi $t3, $zero, 0 # i iterator
	addi $t4, $zero, 0 # j iterator
	add $t5, $zero, $a2
	add $t6, $zero, $a3
	add $t7, $zero, $t5


	CheckEnd:
		beq $t4, $a0, ExitRect # check if we drew all the necessary rows

	DrawHeight:
		beq $t3, $a1, DrawWidth
		sw $t6, ($t7) # save the colour of the rectangle
		addi $t3, $t3, 1 # increment i iterator
		add $t7, $t7, $t2 # increment pixel
		j DrawHeight

	DrawWidth:
		addi $t4, $t4, 1 # increment j iterator
		sll $t7, $t1, 2 # logical left shift
		add $t5, $t5, $t7
		add $t7, $zero, $t5
		addi $t3, $zero, 0
		j CheckEnd

	ExitRect:
		jr $ra


DrawBackground:

	lw $t0, displayAddress

	# draw end grass
	addi $a0, $zero, 8
	addi $a1, $zero, 32
	add $a2, $zero, $t0
	lw $a3, endclr
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal DrawRectangle
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# draw middle grass
	addi $a0, $zero, 4
	addi $a1, $zero, 32
	addi $a2, $t0, 2048
	lw $a3, midclr
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal DrawRectangle
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# draw start grass
	addi $a0, $zero, 4
	addi $a1, $zero, 32
	addi $a2, $t0, 3584
	lw $a3, grassclr
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal DrawRectangle
	lw $ra, ($sp)
	addi $sp, $sp, 4

	jr $ra


DrawHearts:

	lw $t3, displayAddress
	addi $t2, $t3, 132 # go to address of first heart

	lw $t1, lives
	add $t5, $zero, $t1 # store current number of lives in $t5
	lw $t0, heartclr
	addi $t4, $zero, 1 # store 1 to compare lives

	bge $t5, $t4, DrawHeart # draw the first heart if we still have at least 1 life
	j EndDrawHearts

	DrawHeart:
		sw $t0, ($t2)
		sw $t0, 8($t2)
		addi $t2, $t2, 128
		sw $t0, ($t2)
		sw $t0, 4($t2)
		sw $t0, 8($t2)
		addi $t2, $t2, 128
		sw $t0, ($t2)
		sw $t0, 4($t2)
		sw $t0, 8($t2)
		addi $t2, $t2, 128
		sw $t0, 4($t2)

		addi $t5, $t5, -1
		addi $t2, $t2, -368
		bge $t5, $t4, DrawHeart # draw another heart if we have more lives than hearts drawn
		j EndDrawHearts # stop drawing hearts if we have drawn the same amount as current lives

	EndDrawHearts:
		jr $ra


DrawCar:

	# $a2: top left pixel of car
	# $a3: colour
	addi $t5, $zero, 1
	beq $t4, $t5, RightCar # branch if the car is facing right
	j LeftCar # else branch to draw car facing left

	LeftCar:
		add $t3, $zero, $a2 # top left pixel
		add $t4, $zero, $a3 # colour

		sw $t4, 12($t3)
		sw $t4, 16($t3)
		sw $t4, 20($t3)
		sw $t4, 24($t3)
		sw $t4, 28($t3)
		addi $t3, $t3, 128
		sw $t4, ($t3)
		sw $t4, 4($t3)
		sw $t4, 8($t3)
		sw $t4, 12($t3)
		sw $t4, 16($t3)
		sw $t4, 20($t3)
		sw $t4, 24($t3)
		sw $t4, 28($t3)
		addi $t3, $t3, 128
		sw $t4, ($t3)
		sw $t4, 4($t3)
		sw $t4, 8($t3)
		sw $t4, 12($t3)
		sw $t4, 16($t3)
		sw $t4, 20($t3)
		sw $t4, 24($t3)
		sw $t4, 28($t3)
		addi $t3, $t3, 128
		sw $t4, 4($t3)
		sw $t4, 24($t3)

		jr $ra


	RightCar:
		add $t3, $zero, $a2 # top left pixel
		add $t4, $zero, $a3 # colour

		sw $t4, ($t3)
		sw $t4, 4($t3)
		sw $t4, 8($t3)
		sw $t4, 12($t3)
		sw $t4, 16($t3)
		addi $t3, $t3, 128
		sw $t4, ($t3)
		sw $t4, 4($t3)
		sw $t4, 8($t3)
		sw $t4, 12($t3)
		sw $t4, 16($t3)
		sw $t4, 20($t3)
		sw $t4, 24($t3)
		sw $t4, 28($t3)
		addi $t3, $t3, 128
		sw $t4, ($t3)
		sw $t4, 4($t3)
		sw $t4, 8($t3)
		sw $t4, 12($t3)
		sw $t4, 16($t3)
		sw $t4, 20($t3)
		sw $t4, 24($t3)
		sw $t4, 28($t3)
		addi $t3, $t3, 128
		sw $t4, 4($t3)
		sw $t4, 24($t3)

		jr $ra


DrawDynamic:
	# draw the dynamic objects (logs + cars)

	# draw top row of logs
	lw $t0, displayAddress
	la $a0, logArray1
	lw $a1, logclr
	lw $a2, waterclr
	addi $a3, $t0, 1024 # set $a3 to the top left corner of the top log row
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal DrawObj
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# draw bottom row of logs
	lw $t0, displayAddress
	la $a0, logArray2
	addi $a3, $t0, 1536 # set $a3 to the top left corner of the bottom log row
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal DrawObj
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# draw top row of cars
	lw $t0, displayAddress
	la $a0, carArray1
	lw $a1, carclr
	lw $a2, roadclr
	addi $a3, $t0, 2560 # set $a3 to the top left corner of the top car row
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal DrawObj
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# draw bottom row of cars
	lw $t0, displayAddress
	la $a0, carArray2
	addi $a3, $t0, 3072 # set $a3 to the top left corner of the bottom car row
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal DrawObj
	lw $ra, ($sp)
	addi $sp, $sp, 4

	jr $ra


DrawObj:
	# $a0: top left corner of the array
	# $a1: colour address of the object (car or log)
	# $a2: colour address of the background (road or water)
	# $a3: top left corner of the object we are drawing
	# note that 1 represents presence of object while 0 represents presence of background

	add $t0, $zero, $a3 # set $t0 to $a3
	add $t1, $zero, $a0 # set $t1 to $a0
	addi $t2, $zero, 128 # 4 rows (height of objects) is 128 pixels total
	addi $t3, $zero, 1 # to check for presence of dynamic object
	addi $t4, $zero, 0

	LoopObj:
		beq $t4, $t2, EndObj # loops until we fill 128 pixels
		lw $t5, ($t1) # get address stored inside $t1
		beq $t5, $t3, DrawOneObj # draw obstacle if it contains 1

	RedrawBackground:
		sw $a2, ($t0) # otherwise draw background
		j IncrementObj

	DrawOneObj:
		sw $a1, ($t0) # draw dynamic object

	IncrementObj:
		addi $t4, $t4, 1
		addi $t0, $t0, 4
		addi $t1, $t1, 4
		j LoopObj

	EndObj:
		jr $ra


DrawFroggie:

	lw $t0, frogAddress
	add $t1, $zero, $t0 # store frog address in $t1
	lw $t2, frogclr
	la $t3, direction
	lw $t4, ($t3) # load frog's direction into $t4
	addi $t5, $zero, 0
	beq $t4, $t5, UpFroggie # draw frog facing up if its direction is set to 0
	addi $t5, $zero, 1
	beq $t4, $t5, LeftFroggie # draw frog facing up if its direction is set to 1
	addi $t5, $zero, 2
	beq $t4, $t5, BackFroggie # draw frog facing up if its direction is set to 2
	addi $t5, $zero, 3
	beq $t4, $t5, RightFroggie # draw frog facing up if its direction is set to 3


	UpFroggie:
		sw $t2, ($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)

		jr $ra


	LeftFroggie:
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 12($t1)

		jr $ra


	BackFroggie:
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 12($t1)

		jr $ra


	RightFroggie:
		sw $t2, ($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 4($t1)
		sw $t2, 8($t1)
		addi $t1, $t1, 128
		sw $t2, ($t1)
		sw $t2, 8($t1)
		sw $t2, 12($t1)

		jr $ra


MoveObj:

	# shift top row of logs
	la $a0, logArray1
	addi $a1, $zero, 1 # 1 corresponds to shift right
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal Shifter
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# shift bottom row of logs
	la $a0, logArray2
	addi $a1, $zero, 0 # 0 corresponds to shift left
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal Shifter
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# shift bottom row of logs a second time to make it faster
	la $a0, logArray2
	addi $a1, $zero, 0 # 0 corresponds to shift left
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal Shifter
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# shift top row of cars
	la $a0, carArray1
	addi $a1, $zero, 0 # 0 corresponds to shift left
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal Shifter
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# shift top row of cars a secong time to make them faster
	la $a0, carArray1
	addi $a1, $zero, 0 # 0 corresponds to shift left
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal Shifter
	lw $ra, ($sp)
	addi $sp, $sp, 4

	# shift bottom row of cars
	la $a0, carArray2
	addi $a1, $zero, 1 # 1 corresponds to shift right
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal Shifter
	lw $ra, ($sp)
	addi $sp, $sp, 4

	addi $s0, $zero, 0 # reset the loop condition to 0

	jr $ra


Shifter:

	# $a0: top left corner of array
	# $a1: either 1 or 0 where 1 corresponds to shift right and 0 corresponds to shift left
	# shifts the objects row by row (4 times)

	addi $sp, $sp, -4
	sw $ra, ($sp)

	addi $t0, $zero, 1 # 1 represents a row moving right
	addi $t6, $zero, 4 # counter for how many rows we've drawn
	addi $t7, $zero, 0 # stores 0 to compare rows

	beq $a1, $t0, ShiftRowRight # branch if the row is moving right
	j ShiftRowLeft # else: move left

	ShiftRowLeft:
		jal ShiftLeft # shifts a whole row left
		addi $t6, $t6, -1 # decrement counter
		bgt $t6, $t7, NextRow # shifts next row if less than 4 rows have been shifted
		j EndShift # return if 4 rows have been drawn

	ShiftRowRight:
		jal ShiftRight # shifts a whole row right
		addi $t6, $t6, -1 # decrement counter
		bgt $t6, $t7, NextRow # shifts next row if less than 4 rows have been shifted
		j EndShift # return if 4 rows have been drawn

	NextRow:
		addi $a0, $a0, 128 # move pointer to next row
		addi $t0, $zero, 1 # reset $t0 to 1
		beq $a1, $t0, ShiftRowRight
		jal ShiftRowLeft
		j NextRow

	EndShift:
		lw $ra, ($sp)
		addi $sp, $sp, 4
		jr $ra


	ShiftRight:

		# $a0: top left corner of the array
		add $t0, $zero, $a0
		addi $t1, $zero, 0 # loop incrementer
		addi $t2, $zero, 32 # iterates 32 times since 128/4 = 32
		addi $t3, $t0, 124 # pointer to the last element in row
		lw $t4, ($t3) # carry

		LoopRight:
			beq $t1, $t2, EndShiftRight
			lw $t5, ($t0)
			sw $t4, ($t0) # draw pixel
			add $t4, $t5, $zero

		ShiftRightIncrement:
			addi $t1, $t1, 1
			addi $t0, $t0, 4
			j LoopRight

		EndShiftRight:
			jr $ra


	ShiftLeft:

		# $a0: top left corner of the array
		addi $t0, $a0, 124 # pointer to the last element in row
		addi $t1, $zero, 0 # loop incrementer
		addi $t2, $zero, 32 # iterates 32 times since 128/4 = 32
		lw $t4, ($a0)

		LoopLeft:
			beq $t1, $t2, EndShiftLeft
			lw $t5, ($t0)
			sw $t4, ($t0) # draw pixel
			add $t4, $t5, $zero

		ShiftLeftIncrement:
			addi $t1, $t1, 1
			addi $t0, $t0, -4
			j LoopLeft

		EndShiftLeft:
			jr $ra



Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

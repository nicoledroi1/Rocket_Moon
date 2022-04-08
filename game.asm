##################################################################### 
# 
# CSCB58 Winter 2022 Assembly Final Project 
# University of Toronto, Scarborough 
# 
# Student: Nicole Droi, 1006971499, droinico, n.droi@mail.utoronto.ca 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 (update this as needed)  
# - Unit height in pixels: 8 (update this as needed) 
# - Display width in pixels: 512 (update this as needed) 
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 ($gp) 
# 
# Which milestones have been reached in this submission? 
# (See the assignment handout for descriptions of the milestones) 
# - Milestone 1/2/3 (choose the one the applies) 
#	- Milestones 1
#	- Milestones 2
#	- Milestones 3
# 
# Which approved features have been implemented for milestone 3? 
# (See the assignment handout for the list of additional features) 
# 1. Health/Score (2 pts)
# 2. Fail condition (1 pt)
# 3. Moving Platforms (2 pts)
#	- The platforms are always moving
# 4. Pick-up effects (2 pts)
# 	- The yellow star pickup gives a jump boost for 5 seconds
# 	- The pink star pickup regenerates a heart (if the player has 3 already it does nothing)
# 	- The gray star pickup allows the user to not lose a heart for 5 seconds (game over still applies if the rocket reached the bottom of the screen)
# 5. Disappearing platforms (2 pts)
# ... (add more if necessary) 
# 
# Link to video demonstration for final submission: 
# - https://youtu.be/3wl-69Rw3ek 
# 
# Are you OK with us sharing the video with people outside course staff? 
# - yes, https://github.com/nicoledroi1/Rocket_Moon
# 
# Any additional information that the TA needs to know: 
# - Every 15 seconds a platform disapears
# - Every 30 seconds the meteors start to move faster (the delay gets .1 seconds shorter, can min be .4 seconds)
# 	- If the delay is less than or equal to .6 then the rockets gravity pull increases
# 
##################################################################### 

#general constants
.eqv	NUM_ROW_PIXEL	256
.eqv	CLEAR_VALUE	1
.eqv	NUM_METEORS	80
.eqv	NUM_STARS	8
.eqv	FIRST_ADDRESS	0x10008000

#colour constants
.eqv	BLACK_COLOUR		0x000000

.eqv	DARK_METEOR_COLOUR1	0x333334
.eqv	DARK_METEOR_COLOUR2	0x202329
.eqv	DARK_METEOR_COLOUR3	0x232027
.eqv	LIGHT_METEOR_COLOUR	0x595a5c

.eqv	HEART_COLOUR		0xdc20f2

.eqv	RED_ROCKET_COLOUR	0x941a1a
.eqv	BLUE_ROCKET_COLOUR	0x2c5198

.eqv	DARK_EARTH_COLOUR	0x0f5e0f
.eqv	LIGHT_EARTH_COLOUR	0x228B22

.eqv	WORD_COLOUR		0x2c5198

.eqv	DARK_STAR_COLOUR	0xd1d40b
.eqv	LIGHT_STAR_COLOUR	0xf3f660

.eqv	WHITE_COLOUR		0xffffff

.data
frameBuffer: 	.space 		0x80000 #512 wide x 256 high pixels

#arrays to store locations
meteors: 	.space		NUM_METEORS #an array that stores the meteors positions
in_meteors: 	.space 		NUM_METEORS #an array that stores if the meteors are in the screen or not

collected_stars:	.space		NUM_STARS #stores if a the type of star at that index was collected (0 = yellow, 1 = pink, 2 = grey)
pink_stars_meteors: 	.space		NUM_METEORS #an array that stores if the meteor at that index has a pink star on it
yellow_stars_meteors: 	.space		NUM_METEORS #an array that stores if the meteor at that index has a yellow star on it
gray_stars_meteors: 	.space		NUM_METEORS #an array that stores if the meteor at that index has a yellow star on it

.text
.globl main

main:
	
	jal CLEAR 		#clearing the screen in case anything was there previously
	
	j START_BACKGROUND 	#jumping to START_BACKGROUND to draw the starting background
	
STARTING_GAME_POSITION:

	#sleeping for 3 second before clearing the screen and starting the game
	li $v0, 32
	li $a0, 3000
	syscall
	
	j CLEAR_START_BACKGROUND #clearing the start background more efficiently
	
CLEARED:

#----------- Global Variables -----------#
	
	li $s0, 0 #need to be colliding for at least .7 second(s) in order to lose a heart
	li $s1, 0 #storing location of rocket
	li $s2, 0 #stores time gone by since getting the yellow star
	li $s3, 3 #stores the total number of hearts the player currently has
	li $s4, 0 #if the rocket is on a meteor
	li $s5, 0 #stores how much time passes since collecting a gray star
	li $s6, 1 #this will become a time counter
	li $s7, 0 #represents if a was pressed
	li $v1, 8 #stores how much time we wait before moving the meteors down
	
#----------------------------------------#

#------------------- Initializing the bigger arrays ---------------------#

	li $t7, NUM_METEORS 	#used as a counter for our loop
	la $a0, in_meteors	#loading the address of the in_meteors array
	
	la $a1, yellow_stars_meteors 	#loading the first address of the yellow_stars_array
	la $a2, pink_stars_meteors	#loading the first address of the pink_stars_array
	la $a3, gray_stars_meteors	#loading the first address of the gray_stars_array
			
INITALIZE_IN_METEOR_AND_STARS:
	
	sw $zero, 0($a0) 	#saving zero because the meteor isn't in the screen
	sw $zero, 0($a1) 	#saving zero because the star isn't on the meteor
	sw $zero, 0($a2) 	#saving zero because the star isn't on the meteor
	sw $zero, 0($a3) 	#saving zero because the star isn't on the meteor
	
	addi $a0, $a0, 4 	#moving to the next element
	addi $a1, $a1, 4 	#moving to the next element
	addi $a2, $a2, 4 	#moving to the next element
	addi $a3, $a3, 4 	#moving to the next element
	
	addi $t7, $t7, -4 	#decrementing our counter
	beqz $t7, END_INTALIZE 	#if we've intialized every element we're done
	
	j INITALIZE_IN_METEOR_AND_STARS

#--------------------------------------------------------------------------------#
	

END_INTALIZE:

#------------------- Initializing the collected stars array ---------------------#

	la $a0, collected_stars	#loading the address of our collected_stars array
	sw $zero, 0($a0)	#saving zero because the meteor isn't in the screen
	sw $zero, 4($a0) 	#saving zero because the meteor isn't in the screen
	sw $zero, 8($a0) 	#saving zero because the meteor isn't in the screen
	
#--------------------------------------------------------------------------------#


#------------------- Drawing and initializing our start meteors ---------------------#
	
	#Meteor 1
	li $a0, 7540 	#4*(29*64+29) - our index of the meteor
	
	la $a1, meteors #loading the meteor array
	sw $a0, 0($a1) 	#saving the location of the platform in the second index of the meteor
	
	li $t6, CLEAR_VALUE
	
	la $a1, in_meteors
	sw $t6, 0($a1) 	#saving 1 because the meteor is in the screen
	
	#pushing the colour of the meteor on the stack
	addi $sp, $sp, -4 
	li $t6, DARK_METEOR_COLOUR1
	sw $t6, 0($sp)
	
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $a0, 0($sp)
	
	jal DRAW_METEOR
	
	#Meteor 2
	li $a0, 5180 	#4*(20*64+15) - our index of the meteor
	
	la $a1, meteors #loading the meteor array
	sw $a0, 4($a1) 	#saving the location of the platform in the second index of the meteor
	
	#pushing the colour of the meteor on the stack
	addi $sp, $sp, -4 
	li $t6, DARK_METEOR_COLOUR2
	sw $t6, 0($sp)
	
	li $t6, CLEAR_VALUE
	la $a1, in_meteors
	sw $t6, 4($a1) 	#saving 1 because the meteor is in the screen
		
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $a0, 0($sp)
	
	jal DRAW_METEOR
	
	#Meteor 3
	li $a0, 3016 	#4*(11*64+50) - our index of the meteor
	
	la $a1, meteors
	sw $a0, 8($a1) 	#saving the location of the platform in the third index of the meteor
	
	li $t6, CLEAR_VALUE
	la $a1, in_meteors
	sw $t6, 8($a1) 	#saving 1 because the meteor is in the screen
	
	#pushing the colour of the meteor on the stack
	addi $sp, $sp, -4 
	li $t6, DARK_METEOR_COLOUR3
	sw $t6, 0($sp)
		
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $a0, 0($sp)
	
	jal DRAW_METEOR

#--------------------------------------------------------------------------------#



#------------------- Drawing and initializing drawing our rocket ---------------------#

#Start location for the rocket
	li $s1, 6256 	#4*(24*64+28) - our index of the line
		
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)
	
	jal DRAW_ROCKET	

#--------------------------------------------------------------------------------#

	jal DRAWING_NUM_HEARTS	#Drawing the heartsthe player has

#------------------- Initializing the locations of the meteor ---------------------#
RANDOMIZED_LOCATIONS:
	
	la $t7, meteors		#loading the address of the meteor array
	addi $t7, $t7, 16 	#since the first 3 elements are already set we get the address of the fourth element in the array
	
	li $t8, NUM_METEORS 	#using as our counter
	addi $t8, $t8, -12 	#want one less since we've already initalized three of our positions
	
	METEOR_LOOP:
		#getting a random number for the position of the meteor
		li $v0, 42
		li $a0, 5
		
		#getting a random number from 0 to the last index of the first row of pixels, since the meteors will be dropping in
		li $a1, 58
		syscall
		
		#our random number is now in $a0
		sll $a0, $a0, 2 	#need to multiply by 4 to get a valid location
		sw $a0, 0($t7) 		#saving the position of the meteor
		
		#just saving the positions for now
		addi $t7, $t7, 4 	#moving to the next element of the array
		addi $t8, $t8, -4 	#decrementing the counter
		
		beqz $t8, STARTING_ACTUAL_GAME	#if the our temp is equal to 0 we've intialized each position
		j METEOR_LOOP

#--------------------------------------------------------------------------------#

#------------------- Main game loop!!! ---------------------#
STARTING_ACTUAL_GAME:
	
	#------------------- Checking if the key was pressed ---------------------#
	li $t9, 0xffff0000  
	lw $t8, 0($t9) 
	beq $t8, 1,KEY_PRESSED 
	#-------------------------------------------------------------------------#
	
AFTER_KEYS:

	#---------- Checking if we need to increase how fast the meteor goes down (every 30 seconds) ----------#
	
	li $t7, 300 	#loading 300 as our mod value (30 seconds)
	div $s6, $t7 	#s6 mod 300
	mfhi $t8
	
	beqz $t8, INCREASE_SPEED_MAYBE 	#if the mod value is 0 we increase the speed accordingly
	
	j CONT_MAIN_LOOP
	
	INCREASE_SPEED_MAYBE:
		#if the meteors are going down at every .4 seconds we no longer increase the speed
		li $t7, 4
		beq $t7, $v1, CONT_MAIN_LOOP 	#if it is 4 we no longer increase
		
		YES_INCREASE_SPEED:
			addi $v1, $v1, -1 	#decresing the time between moving the meteors down
	
	#------------------------------------------------------------------------------------------------------#
			
CONT_MAIN_LOOP:
	
	jal IS_ON_METEOR 	#checking if the rocket is on a meteor and setting $s4 accordingly
	
	#---------- Dealing with platform disappearence (every 15 secs) ----------#
	
	li $t7, 150 	#loading 150 as our mod value (15 secs)
	div $s6, $t7 	#s6 mod 150
	mfhi $t8
	
	bnez $t8, CONT_MOVING 	#15 seconds has not passed
	
	jal REMOVE_PLATFORM 	#remove the platform
	
	#-------------------------------------------------------------------------#
	
CONT_MOVING:
	
	#-------------------------- Checking for star pickups ---------------------------------#
	la $a3, collected_stars
	lw $t7, 0($a3)
	
	beqz $t7, CHECK_GRAY_TIME
	
	#increment how much time the yellow star was collected for
	addi $s2, $s2, 1

	NEXT_CHECKING:
	#if 5 seconds has passed then we remove the boost jump
		li $t7, 50 	#loading 50 as our mod valu
		div $s2, $t7 	#s2 mod 50
		mfhi $t8
	
		bnez $t8, CHECK_GRAY_TIME 	#5 seconds has not passed
		sw $zero, 0($a3) 		#5 seconds passed so we reset the boost

	CHECK_GRAY_TIME:
	#checking if we need to add to our gray star timer
	la $a3, collected_stars
	lw $t7, 8($a3)
	
	beqz $t7, HAS_TIME
	
	#increment how much time the gray star was collected for
	addi $s5, $s5, 1
	
	NEXT_CHECKING1:
	#if 5 seconds has passed then we remove the can't lose a life
		li $t7, 50 	#loading 50 as our mod value
		div $s5, $t7 	#s5 mod 50
		mfhi $t8
	
		bnez $t8, HAS_TIME 	#5 seconds has not passed
		sw $zero, 8($a3) 	#5 seconds passed so we reset the no collision
		
	#-------------------------------------------------------------------------------#
	
	#--------------- Checking if we need to add a new meteor and/or star -------------------#
	
	#checking if 2.5 or 1.5 seconds passed, if yes we add in a new meteor
	HAS_TIME:
		li $t7, 25 			#loading 25 as our mod value
		bgt $v1, 6, CONT_HAS_TIME 	#if we move the meteors down more than every .6 seconds we do not add new meteors
		li $t7, 15 			#loading with 15 so the ratio remains somewhat similar
		
	CONT_HAS_TIME:
		div $s6, $t7 			#s6 mod 25 or 15
		mfhi $t8
		
		beqz $t8, YES 			#we do add a new meteor
		j NO
	YES:
		li $t6, 0 			#stores if the last value was a 1 in our in meteors array
		li $t8, NUM_METEORS
		la $a0, in_meteors 		#loading the address of the first element of our filter
		la $a1, yellow_stars_meteors 	#loading the address of the first element of the yellow stars
		la $a2, pink_stars_meteors 	#loading the address of the first element of the pink stars
		la $a3, gray_stars_meteors 	#loading the address of the first element of the gray stars
		
		CHECK_ARRAY:
			lw $t7, 0($a0) 		#getting the if the meteor at this index is in the frame or not
			bne $t6, 1, END_CHECK 	#if the last value was not one we don't care
			bnez $t7, END_CHECK 	#if the current value is not 0 then we end the checking
			
			#adding in our next meteor in the array
			li $t6, CLEAR_VALUE
			sw $t6, 0($a0)
		
		#checking if we should add stars depending on time
		
		CHECK_YELLOW:	
		#if 10 seconds pass we add a yellow star onto the meteor that we are adding
			li $t5, 100 		#loading 100 as our mod value
			div $s6, $t5 		#s6 mod 100
			mfhi $t8
			
			bnez $t8, CHECK_PINK 	#if 10 seconds has not passed we do not add a star
			
			#adding a star in
			li $t6, CLEAR_VALUE
			sw $t6, 0($a1) 		#the meteor at this position will have a yellow star on it
			
			j NO
		
		CHECK_PINK:	
		#if 15 seconds pass we add a pink star onto the meteor that we are adding
			li $t5, 150 		#loading 150 as our mod value
			div $s6, $t5 		#s6 mod 150
			mfhi $t8
			
			bnez $t8, CHECK_GRAY 	#if 15 seconds has not passed we do not add a pink star
			
			#adding a pink star in
			li $t6, CLEAR_VALUE
			sw $t6, 0($a2) 		#the meteor at this position will have a pink star on it
			
			j NO
			
		CHECK_GRAY:	
		#if 25 seconds pass we add a gray star onto the meteor that we are adding
			li $t5, 250 		#loading 250 as our mod value
			div $s6, $t5 		#s6 mod 250
			mfhi $t8
			
			bnez $t8, NO 		#if 250 seconds has not passed we do not add a star
			
			#adding a star in
			li $t6, CLEAR_VALUE
			sw $t6, 0($a3) 		#the meteor at this position will have a star on it
			
			j NO
			
		END_CHECK:
			addi $t6, $t7, 0 	#storing our next last value	
			addi $a0, $a0, 4 	#moving to the next element of the array
			addi $a1, $a1, 4 	#moving to the next element of the array
			addi $a2, $a2, 4 	#moving to the next element of the array
			addi $a3, $a3, 4 	#moving to the next element of the array
			addi $t8, $t8, -4 	#decrementing our counter
			beqz $t8, DONE_CHECK 	#if our counter is 0 then we're done checking
			
			j CHECK_ARRAY 		#continue looping
		
		DONE_CHECK:	
			#we can only be here if the last value was 1 which means we need to set the first value to 1
			li $t8, CLEAR_VALUE
			la $a2, in_meteors
			sw $t8, 0($a2) 		#loading 1 as the value of our first value so we will show the first meteor in the array
			
	#---------------------------------------------------------------------------#
	
	NO:
	
	#--------------- Checking if we need to move the rocket down -------------------#
	
	#moving the rocket down every .2 or .1 seconds to implement 'gravity'
	ARE_MOVING_ROCKET:
		bnez $s4, DONE_DOWN_ROCKET 	#if the rocket is on a meteor we don't move it down as fast as if it wasn't
		bnez $s7, DONE_DOWN_ROCKET 	#if the rocket was moved up previously we don't move it down
		
		#checking if enough time has passed
		li $t7, 2 			#loading 2 as our mod value
		
		bgt $v1, 5, MOVE_ROCKET_MAYBE	#if the meteors are not going down every .5 or .4 secs we don't change our mod value
		
		ARE_MOVING_ROCKET_FASTER:
			li $t7, 1 		#loading 1 as our mod value
			
		MOVE_ROCKET_MAYBE:
		div $s6, $t7 			#s6 mod 2 or 1
		mfhi $t8
		bnez $t8, DONE_DOWN_ROCKET 	#if .2 or .1 (always will) seconds has not passed
		
		jal MOVE_THE_ROCKET_DOWN			#moving rocket down
		
	DONE_DOWN_ROCKET:
	
	#loading 0 since we don't want the rocket to stay in the 'up' position
	li $s7, 0
	
	#-------------------------------------------------------------------------------#
	
	#--------------- Moving the meteor down depending on v1 time -------------------#
	ARE_MOVING_METEOR:
		#we move the meteors down if v1 amount of time has passed
		div $s6, $v1 	#s6 mod v1
		mfhi $t8
		
		bnez $t8, DONE_DOWN
	
	YES_MOVING_METEOR_DOWN:
	
	li $t8, NUM_METEORS
	la $a0, in_meteors 		#getting our array that stores whether the meteor is in the screen
	la $a1, meteors 		#getting the array storing the locations of the meteors
	la $a2, yellow_stars_meteors 	#getting the array storing whether the yellow star is on the meteor
	la $a3, pink_stars_meteors 	#getting the array storing whether the pink star is on the meteor
	la $t9, gray_stars_meteors 	#getting the array storing whether the gray star is on the meteor
	
	MOVING_DOWN:
		lw $t7, 0($a0) 		#getting the boolean value at the current position
		
		beqz $t7, NOT_ON_SCREEN #if the boolean value is 0 then the meteor is not on screen or being moved  
		
		ON_SCREEN:
			#the meteor is on the screen so we need to move it down
			
			lw $t7, 0($a1) 	#getting the location of the meteor 
			
			#checking if we need to initialize a new colour
			bgt $t7, 252, ALREADY_COLOUR
			#the colour has not been initialized yet
			ble $t7, 80, COLOUR3
				
			ble $t7, 160, COLOUR2
			COLOUR1:
				li $t5, DARK_METEOR_COLOUR1
				j CLEAR_THE_METEOR
				
			COLOUR2:
				li $t5, DARK_METEOR_COLOUR2
				j CLEAR_THE_METEOR
				
			COLOUR3:
				li $t5, DARK_METEOR_COLOUR3
				j CLEAR_THE_METEOR
				
			ALREADY_COLOUR:
				#getting the colour of the meteor
				la $fp, frameBuffer
				add $fp, $fp, $t7
				lw $t5, 0($fp)
				
				#we have to check if the following colours were registerd since pickups or other things could be drawn over the meteor
				li $t6, HEART_COLOUR
				bne $t6, $t5, CHECK_BLACK
				
				CHANGE_FROM_PINK:			#checking if the colour was from a pink star or pink heart
					li $t5, DARK_METEOR_COLOUR3
					j CLEAR_THE_METEOR
				
				CHECK_BLACK:				#checking if the colour was taken from the background
					li $t6, BLACK_COLOUR
					bne $t6, $t5, CHECK_YELLOW_DARK
					li $t5, DARK_METEOR_COLOUR3
					j CLEAR_THE_METEOR
					
				CHECK_YELLOW_DARK:			#checking if the colour was taken from the yellow star
					li $t6, DARK_STAR_COLOUR
					bne $t6, $t5, CHECK_LIGHT_GRAY
					li $t5, DARK_METEOR_COLOUR3
					j CLEAR_THE_METEOR
					
				CHECK_LIGHT_GRAY:			#checking if the colour was taken from another meteor
					li $t6, LIGHT_METEOR_COLOUR
					bne $t6, $t5, CHECK_YELLOW_LIGHT
					li $t5, DARK_METEOR_COLOUR3
					j CLEAR_THE_METEOR
					
				CHECK_YELLOW_LIGHT:			#checking if the colour was taken from a star
					li $t6, LIGHT_METEOR_COLOUR
					bne $t6, $t5, CLEAR_THE_METEOR
					li $t5, DARK_METEOR_COLOUR3
					j CLEAR_THE_METEOR
					
					
			CLEAR_THE_METEOR:
			#Clearing the meteor
			#pushing the colour of the meteor on the stack (we don't care since we're clearing)
			addi $sp, $sp, -4 
			li $t6, DARK_METEOR_COLOUR3
			sw $t6, 0($sp)
			
			#pushing the clear value onto the stack
			addi $sp, $sp, -4 
			li $t6, CLEAR_VALUE
			sw $t6, 0($sp)
			
			#pushing the starting index onto the stack
			addi $sp, $sp, -4 
			sw $t7, 0($sp)
	
			jal DRAW_METEOR
			
			#if there is a yellow or pink star or gray clear it
			
			lw $t6, 0($a2)
			bnez $t6, CLEAR_STAR
			
			lw $t6, 0($a3)
			bnez $t6, CLEAR_STAR
			
			lw $t6, 0($t9)
			bnez $t6, CLEAR_STAR
			
			j CONT_ON_SCREEN
			
			CLEAR_STAR:
				#pushing the star colour onto the stack, doesn't matter here since we're clearing
				addi $sp, $sp, -4 
				li $t6, DARK_STAR_COLOUR
				sw $t6, 0($sp)
			
				#pushing the clear value onto the stack
				addi $sp, $sp, -4 
				li $t6, CLEAR_VALUE
				sw $t6, 0($sp)
	
				#pushing the starting index onto the stack
				addi $sp, $sp, -4 
				lw $t7, 0($a1) 		#saving the new location of the meteor
				addi $t7, $t7, -1280 	# 5*(-256)
				sw $t7, 0($sp)
	
				jal DRAW_STAR
			
		CONT_ON_SCREEN:
			
			lw $t7, 0($a1) 			#getting the location of the meteor 
			addi $t7, $t7, 256 		#moving the meteor a row down
			sw $t7, 0($a1) 			#saving the new location of the meteor
			
			bgt $t7, 9216, OUT_OF_SCREEN 	# 9216 = 4*(31*64)+5*256 this value gives us if the meteor is COMPLETELY of the screen
			
			STILL_IN_SCREEN:
				
				#pushing the colour of the meteor on the stack
				addi $sp, $sp, -4 
				sw $t5, 0($sp)
				
				#pushing the clear value onto the stack
				addi $sp, $sp, -4 
				sw $zero, 0($sp)
	
				#pushing the starting index onto the stack
				addi $sp, $sp, -4 
				sw $t7, 0($sp)
	
				jal DRAW_METEOR
				
			#if there's a star we need to redraw
				lw $t6, 0($a2)
				bnez $t6, REDRAW_STAR
				
				lw $t6, 0($a3)
				bnez $t6, REDRAW_STAR
				
				lw $t6, 0($t9)
				bnez $t6, REDRAW_STAR
				
				j NOT_ON_SCREEN
				
				REDRAW_STAR:
					#loading this colour as our base
					li $t6, DARK_STAR_COLOUR
					
					#checking if the star was pink
					lw $t7, 0($a3)
					beqz $t7, GRAY_CHECK
					
					#star is pink
					li $t6, HEART_COLOUR
					
					GRAY_CHECK:
					#checking if the star was gray
					lw $t7, 0($t9)
					beqz $t7, PUSH_STACK
					
					#star is gray
					li $t6, LIGHT_METEOR_COLOUR
					
					PUSH_STACK:
					#pushing the star colour onto the stack
					addi $sp, $sp, -4 
					sw $t6, 0($sp)
				
					#pushing the clear value onto the stack
					addi $sp, $sp, -4 
					sw $zero, 0($sp)
	
					#pushing the starting index onto the stack
					addi $sp, $sp, -4 
					lw $t7, 0($a1) 		#saving the new location of the meteor
					addi $t7, $t7, -1280 	# 5*(-256)
					sw $t7, 0($sp)
	
					jal DRAW_STAR
				
				j NOT_ON_SCREEN
			
			OUT_OF_SCREEN:
				sw $zero, 0($a0) 	#changing this value to 0 since it is off the screen
				addi $t7, $t7, -9216 	#moving the meteor back to the begining of the screen
				
				sw $t7, 0($a1) 		#saving the new location of the meteor
				sw $zero, 0($a2) 	#if there was a star we reset this value to 0 (always doing this to minimize lines)
		
		NOT_ON_SCREEN:
		
		addi $a0, $a0, 4 	#moving to the next index boolean
		addi $a1, $a1, 4 	#moving to the next meteor
		addi $a2, $a2, 4 	#moving to the next star index
		addi $a3, $a3, 4 	#moving to the next star index
		addi $t9, $t9, 4 	#moving to the next star index
		addi $t8, $t8, -4 	#decrementing our counter
		
		beqz $t8, ROCKET_ON_DOWN 	#if the counter is 0 we're done
		
		j MOVING_DOWN
		
	#------------------------------------------------------------------------#
	
	ROCKET_ON_DOWN:
		beqz $s4, DONE_DOWN 	#if the rocket is not on a meteor we do not move it down here
	
		#moving the rocket down
		jal MOVE_THE_ROCKET_DOWN
	
	DONE_DOWN:
	
	jal CHECK_COLLISION 	#checking if there are any collisions
	
	jal DRAWING_NUM_HEARTS 	#drawing how many hearts the player has
	
	#sleeping for 0.1 second before looping back to the beginning
	li $v0, 32
	li $a0, 100
	syscall
	
	addi $s6, $s6, 1 	#adding one to our time counter
	beqz $s3, END 		#if the number of hearts it's game over
	
	j STARTING_ACTUAL_GAME #keep looping

#------------------- End of main game loop!!! ---------------------#

#### Functions dealing with key pressing ####
KEY_PRESSED:
	lw $t2, 4($t9) 			# this assumes $t9 is set to 0xfff0000 from before
	
	beq $t2, 0x61, A_PRESSED   	# ASCII code of 'a' is 0x61
	beq $t2, 0x64, D_PRESSED   	# ASCII code of 'd' is 0x64 
	beq $t2, 0x77, W_PRESSED   	# ASCII code of 'w' is 0x77
	beq $t2, 0x70, P_PRESSED   	# ASCII code of 'p' is 0x70, restart game
		
	j AFTER_KEYS
	
P_PRESSED:
	#if P is pressed
	jal CLEAR
	
	j CLEARED

A_PRESSED:
	#if mod 256 then don't move off
	li $t9, NUM_ROW_PIXEL 	#loading 256
	div $s1, $t9 		#s1 mod 256
	mfhi $t9
	
	beq $t9, 0, AFTER_KEYS
	
	#clearing the rocket
	 
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	li $t6, CLEAR_VALUE
	sw $t6, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)
	
	jal DRAW_ROCKET	
	
	addi $s1, $s1, -4 	#moving the rocket 1 pixel to the left
	
	#redrawing the rocket in the new position
	
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)

	jal DRAW_ROCKET
	
	j AFTER_KEYS
	
W_PRESSED:
	#if we're at the top of the screen don't go further
	blt $s1, 1536, AFTER_KEYS
	
	#need to change if the rocket was moved up so we don't get pushed down
	li $s7, 1
	
	#clearing the rocket
	 
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	li $t6, CLEAR_VALUE
	sw $t6, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)

	jal DRAW_ROCKET	
	
	la $a3, collected_stars
	lw $t6, 0($a3)
	
	li $t7, -256
	beqz $t6, MOVE_UP
	
	#change how much we go up by since the yellow star was collected
	li $t7, -512
	
	MOVE_UP:
	add $s1, $s1, $t7 	#moving the rocket 1 pixel up
	
	#redrawing the rocket in the new position
	
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)
	
	jal DRAW_ROCKET
	
	j AFTER_KEYS
	
D_PRESSED:
	#If the rocket is to the furthest right side we don't move it
	li $t9, NUM_ROW_PIXEL 	#loading 256
	div $s1, $t9 		#s1 mod 256
	mfhi $t9
	
	li $t8, 236

	beq $t9, $t8, AFTER_KEYS

	#clearing the rocket
	 
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	li $t6, CLEAR_VALUE
	sw $t6, 0($sp)
	 
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)
	
	jal DRAW_ROCKET	
	
	addi $s1, $s1, 4 	#moving the rocket 1 pixel to the right
	
	#redrawing the rocket in the new position
	
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)
	
	jal DRAW_ROCKET
	
	j STARTING_ACTUAL_GAME
 
MOVE_THE_ROCKET_DOWN:
	#storing ra in the stack so we can restore it at the end
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#if we're at the bottom of the screen don't go further
	bge $s1, 7936, END 	#if the rocket is at the bottom of the screen it's game over
	
	#clearing the rocket
	
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	li $t6, CLEAR_VALUE
	sw $t6, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)

	jal DRAW_ROCKET	
	
	addi $s1, $s1, 256 	#moving the rocket 1 pixel down
	
	#redrawing the rocket in the new position
	
	#pushing the clear value onto the stack
	addi $sp, $sp, -4 
	sw $zero, 0($sp)
	
	#pushing the starting index onto the stack
	addi $sp, $sp, -4 
	sw $s1, 0($sp)

	jal DRAW_ROCKET
	
DONE_S:
	#restoring ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
 
 
##### Helper Functions #####
REMOVE_PLATFORM:

	#pushing ra onto the stack to restore later
	addi $sp, $sp, -4 
	sw $ra, 0($sp)
	
	GETTING_RANDOM_PLATFORM:
		la $a2, meteors 	#loading the meteors array
		la $a3, in_meteors 	#loading the in meteors array
		
		#getting a random number for the position of the meteor
		li $v0, 42
		li $a0, 0
		
		#getting a random number from 0 to the
		li $a1, 20 		#there are 20 meteors total to delete from
		syscall
		
		sll $a0, $a0, 2 	#need to multiply by 4 to get a valid location
		add $a3, $a3, $a0 	#checking if there is a meteor at this location
		beqz $a3, GETTING_RANDOM_PLATFORM 	#no platform here
		
		#there is a platform so we make it disapear
		sw $zero, 0($a3) 	#removing the platform
		add $a2, $a2, $a0 	#changing to the meteor index we're looking at
		
		YELLOW_STAR:
		#checking if there's a yellow star
		la $a1, yellow_stars_meteors
		add $a1, $a1, $a0
		
		lw $t7, 0($a1)
		beqz $t7, PINK_ERASE 	#not yellow check pink
		sw $zero, 0($a1)	#yellow so change if it's on the meteor
		
		j CLEAR_STAR_DISAPPEAR
		
		PINK_ERASE:
		#checking if there's a pink star
		la $a1, pink_stars_meteors
		add $a1, $a1, $a0
		
		lw $t7, 0($a1)
		bnez $t7, GRAY_ERASE	#not pink check gray
		sw $zero, 0($a1)	#pink so change if it's on the meteor
		
		j CLEAR_STAR_DISAPPEAR
		
		GRAY_ERASE:
		#checking if there's a gray star
		la $a1, gray_stars_meteors
		add $a1, $a1, $a0
		
		lw $t7, 0($a1)		
		bnez $t7, MAKE_METEORS_GONE 	#not gray
		sw $zero, 0($a1)		#gray so change if it's on the meteor
		
		j CLEAR_STAR_DISAPPEAR
		
		CLEAR_STAR_DISAPPEAR:
			#pushing the star colour onto the stack, doesn't matter here since we're clearing
			addi $sp, $sp, -4 
			li $t6, DARK_STAR_COLOUR
			sw $t6, 0($sp)
			
			#pushing the clear value onto the stack
			addi $sp, $sp, -4 
			li $t6, CLEAR_VALUE
			sw $t6, 0($sp)
	
			#pushing the starting index onto the stack
			addi $sp, $sp, -4 
			lw $t7, 0($a2) 		#saving the new location of the meteor
			addi $t7, $t7, -1280	# 5*(-256)
			sw $t7, 0($sp)
	
			jal DRAW_STAR
		
		#Clearing the meteor
		MAKE_METEORS_GONE:
		
		#pushing the colour of the meteor on the stack (we don't care since we're clearing)
		addi $sp, $sp, -4 
		li $t6, DARK_METEOR_COLOUR3
		sw $t6, 0($sp)
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		li $t6, CLEAR_VALUE
		sw $t6, 0($sp)
	
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		lw $t6, 0($a2)
		sw $t6, 0($sp)
	
		jal DRAW_METEOR
		
		#getting a random number for the new staring position of the meteor
		li $v0, 42
		li $a0, 5
		#getting a random number from 0 to 58
		li $a1, 58
		syscall
		
		sll $a0, $a0, 2 	#need to multiply by 4 to get a valid location
		sw $a0, 0($a2) 		#loading it's new starting location
	
	PLATFORM_GONE:
		#prestoring ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4 
	
		jr $ra

CHECK_COLLISION:
	#pushing ra onto the stack to restore later
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#if the rocket is on a meteor then we don't need to check anything here
	bnez $s4, END_COLLISION_CHECK 	#if the rocket has landed on a meteor it won't collide
	
	#loop through each meteor and check if the edges of the rocket are touching any of its edges
	la $a1, meteors 	#loading the meteors array
	la $a2, in_meteors 	#loading the in meteors array
	li $t6, NUM_METEORS 	#getting the number of meteors as our loop counter
	
	#if gray star was collected then we do not detect a collision
	la $a3, collected_stars
	lw $t4, 8($a3)
	bnez $t4, NO_COLLISION
	
	COLLISION_LOOP:
		beqz $t6, END_COLLISION_CHECK 	#if our counter is 0 we finish looping
	
		lw $t1, 0($a2) 			#getting if the meteor is in the screen
		beqz $t1, END_OF_LOOP 		#if the meteor is not in the screen the rocket CANNOT collide with it
		
		lw $t0, 0($a1) 			#getting the current meteors position
		
		#Checking the relevant outside edges of the rocket and extra points
		
		# 1. The top point of the rocket, check all the bottom pixels of the rocket
		TOP_CHECK:
			addi $t2, $s1, -1272 		# 5*(-256) + 8 
			
			#pushing the meteor location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			
			#pushing the index we're currently looking at
			addi $sp, $sp, -4
			sw $t2, 0($sp)
			
			jal CHECKING_ALL_METEOR
			
			#popping the return value
			lw $t3, 0($sp)
			addi $sp, $sp, 4
			
			beqz $t3, COLLISION_DETECTED 	#if the return value is 0 there was a collision	
			
		#2. Check the top pixel of the left most leg of the rocket
		TOP_LEFT_LEG_CHECK:
			addi $t2, $s1, -256
			
			#pushing the meteor location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			
			#pushing the index we're currently looking at
			addi $sp, $sp, -4
			sw $t2, 0($sp)
			
			jal CHECKING_ALL_METEOR
			
			#popping the return value
			lw $t3, 0($sp)
			addi $sp, $sp, 4
			
			beqz $t3, COLLISION_DETECTED 	#if the return value is 0 there was a collision
		
		#3. Check the top pixel of the right most leg of the rocket	
		TOP_RIGHT_LEG_CHECK:
			addi $t2, $s1, -240 		# -256 + 16
			
			#pushing the meteor location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			
			#pushing the index we're currently looking at
			addi $sp, $sp, -4
			sw $t2, 0($sp)
			
			jal CHECKING_ALL_METEOR
			
			#popping the return value
			lw $t3, 0($sp)
			addi $sp, $sp, 4
			
			beqz $t3, COLLISION_DETECTED 	#if the return value is 0 there was a collision
			
	#Extra points that would not be checked in the loop
		
		# 4. Check the middle, left body point of the rocket
		LEFT_CHECK:
			#only checking one "blindspot" point because the other points will be checked with the legs
			
			addi $t2, $s1, -764 	# 3*(-256) + 4
			addi $t3, $t0, -492 	# 2*(-256) + 20
			beq $t2, $t3, COLLISION_DETECTED
			
		# 5. Check the top left body point of the rocket
		TOP_LEFT_CHECK:
			#only checking one "blindspot" point because the other points will be checked with the legs
			
			addi $t2, $s1, -1020 	# 4*(-256) + 4
			addi $t3, $t0, -492 	# 2*(-256) + 20
			beq $t2, $t3, COLLISION_DETECTED
			
		# 6. Check the middle, right body point of the rocket
		RIGHT_CHECK:
			#checking a couple "blindspot" points because the other points will be checked with the legs
			
			addi $t2, $s1, -756 	# 3*(-256) + 12
			addi $t3, $t0, -520	# 2*(-256) - 8
			beq $t2, $t3, COLLISION_DETECTED
			
			#checking the next pixel
			addi $t3, $t0, -264 	# -256 - 8
			beq $t2, $t3, COLLISION_DETECTED
			
		# 7. Check the top, right body point of the rocket	
		TOP_RIGHT_CHECK:
			#only checking one "blindspot" point because the other points will be checked with the legs
			
			addi $t2, $s1, -1012 	# 4*(-256) + 12
			addi $t3, $t0, -264 	# -256 - 8
			beq $t2, $t3, COLLISION_DETECTED	
		
		j END_OF_LOOP
			
	COLLISION_DETECTED:
		addi $s0, $s0, 1 	#adding to the amount of time the collision happened
		
		li $t4, 7 		#the amount of time that the collision should happen for in order to lose a heart
		bne $s0, $t4, END_COLLISION_CHECK
		
		#removing/clearing a heart
		li $s0, 0 		#returning s0 to 0
		addi $s3, $s3, -1 	#removing a heart
		
		mul $t2, $s3, -24 	#getting how far the heart we want to clear is
		addi $t2, $t2, 492 	#the location of the heart to clear
		li $t4, CLEAR_VALUE 	#loading the clear value
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $t4, 0($sp)
	
		#pushing the index onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
	
		jal DRAW_HEART
	
		j END_COLLISION_CHECK
		
	END_OF_LOOP:
		addi $a1, $a1, 4 	#moving to the next element of meteors
		addi $a2, $a2, 4 	#moving to the next element of in_meteor
		addi $t6, $t6, -4 	#decrementing our counter
		j COLLISION_LOOP
	
	NO_COLLISION:
		#if we're here there was no collision and we reset s0
		li $s0, 0
	
	END_COLLISION_CHECK:
 		
		#restoring ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
		jr $ra #returning  
		
CHECKING_ALL_METEOR:
	#getting the rocket pixel which we are checking
	lw $t8, 0($sp) 
	addi $sp, $sp, 4
	
	#getting the meteor location
	lw $t7, 0($sp) 
	addi $sp, $sp, 4
	
	li $t5, -1 	#return value, if 0 there was a collision
	
	CHECKING_ROWS:
		ROW1:
			addi $t3, $t7, -264 	# -256 - 8: second last row, most left meteor pixel
			blt $t8, $t3, ROW2
			
			addi $t3, $t3, 24 	#second last row, most right meteor pixel
			bgt $t8, $t3, ROW2
			
			#there is a collision here on the second last row
			li $t5, 0 
			j DONE_ROW_CHECK
			
		ROW2:
			addi $t3, $t7, 0 	#loading the original start pixel again
			blt $t8, $t3, ROW3
			
			addi $t3, $t3, 12 	#right most bottom meteor pixel
			bgt $t8, $t3, ROW3
			
			#there is a collision here on the second last row
			li $t5, 0 
			j DONE_ROW_CHECK
			
		ROW3:
			addi $t3, $t7, -520 	# 2*(-256) - 8
			blt $t8, $t3, ROW4
			
			addi $t3, $t3, 28 	#right most bottom meteor pixel
			bgt $t8, $t3, ROW4
			
			#collision detecte
			li $t5, 0
			j DONE_ROW_CHECK
			
		ROW4:
			addi $t3, $t7, -776 	# 3*(-256) - 8
			blt $t8, $t3, ROW5
			
			addi $t3, $t3, 28 	#right most bottom meteor pixel
			bgt $t8, $t3, ROW5
			
			#collision detected
			li $t5, 0 
			j DONE_ROW_CHECK
			
		ROW5:
			addi $t3, $t7, -1028 	# 4*(-256) - 4
			blt $t8, $t3, DONE_ROW_CHECK
			
			addi $t3, $t3, 20 	#max row pixel
			bgt $t8, $t3, DONE_ROW_CHECK
			
			#collision detected
			li $t5, 0 
			j DONE_ROW_CHECK
	
	DONE_ROW_CHECK:
		#no collision here return
		
		#pushing the return value onto the stack
		addi $sp, $sp, -4
		sw $t5, 0($sp)
		
		jr $ra
			
DRAWING_NUM_HEARTS:
	#Drawing hearts
	
	addi $t4, $s3, 0 	#using as a counter to draw the hearts
	li $t5, 492 		#loading the location of the first heart
	li $t7, CLEAR_VALUE 	#loading the clear value
	
	#storing the original ra on the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	DRAWING_HEARTS_START:
		beqz $t4, END_DRAWING_HEARTS_START 	#if there are no more hearts to draw we end drawing
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $zero, 0($sp)
	
		#pushing the index onto the stack
		addi $sp, $sp, -4 
		sw $t5, 0($sp)
	
		jal DRAW_HEART
	
		addi $t5, $t5, -24			#decrement the start loaction of the heart
		addi $t4, $t4, -1 			#decrement our counter
		j DRAWING_HEARTS_START
		
	END_DRAWING_HEARTS_START:
		#restoring $ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
		jr $ra 					#jump back from where it came


IS_ON_METEOR:
	li $t8, NUM_METEORS 		#using this as our counter
	la $a0, pink_stars_meteors 	#getting the array storing if there is a pink star on the meteor
	la $a1, meteors 		#getting the array storing the locations of the meteors
	la $a2, in_meteors 		#getting the array storing if the meteor is on the screen or not
	la $a3, yellow_stars_meteors 	#getting the array storing if there is a yellow star on the meteor
	la $t9, gray_stars_meteors 	#getting the array storing if there is a gray star on the meteor
	
	CHECKING:
		beqz $t8, DONE_IS_ON_METEOR
		
		lw $t7, 0($a2) 		#loading if the current meteor is on the screen
		beqz $t7, END_CHECKING 	#if the meteor is not on the screen then we move to the next meteor
		
		lw $t7, 0($a1) 		#getting the position of the current meteor
		addi $t6, $s1, 1280 	#moving down 5 rows
		addi $t7, $t7, -20 	#getting the most left position the rocket could be at
		blt $t6, $t7, END_CHECKING #if the rocket is too far to the left
		
		addi $t7, $t7, 36 		#getting the most right position the rocket could be at
		bgt $t6, $t7, END_CHECKING 	#if the rocket is too far to the right 
		
	YES_ROCKET_DOWN:
		#we know that the rocket is on the meteor in a proper position
		li $s4, 1 #setting the value to 1 
		
		#checking if there is star
		lw $t8, 0($a3) 		#loading the boolean value telling us if there is a star on the meteor
		bnez $t8, STAR_ON_METEOR
		
		lw $t8, 0($a0) 		#loading the boolean value telling us if there is a star on the meteor
		bnez $t8, STAR_ON_METEOR
		
		lw $t8, 0($t9) 		#loading the boolean value telling us if there is a star on the meteor
		bnez $t8, STAR_ON_METEOR
		
		jr $ra
		
		STAR_ON_METEOR:
			#pushing ra onto the stack to restore later
			addi $sp, $sp, -4
			sw $ra, 0($sp)
			
			lw $t7, 0($a1) 
			#pushing the index of the meteor on the stack
			addi $sp, $sp, -4
			sw $t7, 0($sp)
			
			jal STAR_COLLISION
			
			#getting the return value
			lw $t6, 0($sp)
			addi $sp, $sp, 4
			
			beqz $t6, DONE_STAR_ON_METEOR
			
			#pushing the star colour onto the stack
			addi $sp, $sp, -4 
			li $t6, DARK_STAR_COLOUR
			sw $t6, 0($sp)
			
			li $t6, CLEAR_VALUE
			#pushing the clear value on the stack
			addi $sp, $sp, -4
			sw $t6, 0($sp)
			
			lw $t7, 0($a1) 
			addi $t7, $t7, -1280
			#pushing the index of the star on the stack
			addi $sp, $sp, -4
			sw $t7, 0($sp)
			
			jal DRAW_STAR
			
			lw $t8, 0($a0) 		#getting if there is a pink star on the meteor
			bnez $t8, PINK_STAR_COLLISION
			
			lw $t8, 0($t9) 		#getting if there is a gray star on the meteor
			bnez $t8, GRAY_STAR_COLLISION
			
			#there was a collision
			YELLOW_STAR_COLLISION:
			sw $zero, 0($a3) 	#removing the star from the meteor
			li $t6, CLEAR_VALUE
			la $a3, collected_stars
			sw $t6, 0($a3)
			j DONE_STAR_ON_METEOR
			
			PINK_STAR_COLLISION:
			sw $zero, 0($a0) 	#removing the star from the meteor
			beq $s3, 3, DONE_STAR_ON_METEOR 	#if the number of hearts is 3 we do not restore a heart
			addi $s3, $s3, 1 	#restore a heart
			j DONE_STAR_ON_METEOR
			
			GRAY_STAR_COLLISION:
			sw $zero, 0($t9) 	#removing the star from the meteor
			
			li $t6, CLEAR_VALUE
			la $a3, collected_stars
			sw $t6, 8($a3)		
			
		li $s0, 0 		#making sure the collision is set to 0
			
		DONE_STAR_ON_METEOR:	
			#restoring ra
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			
			jr $ra
		
	END_CHECKING:
		addi $a0, $a0, 4 	#moving to the next element
		addi $a1, $a1, 4 	#moving to the position of the next meteor
		addi $a2, $a2, 4 	#moving to the next element
		addi $a3, $a3, 4 	#moving to the next element
		addi $t9, $t9, 4 	#moving to the next element
		addi $t8, $t8, -4 	#decrementing our counter
		j CHECKING
	
	DONE_IS_ON_METEOR:
		li $s4, 0		#setting the value to 0 since the rocket is not on the meteor 
		jr $ra


STAR_COLLISION:
	#getting the index of the meteor
	lw $t7, 0($sp)
	addi $sp, $sp, 4
	
	li $t8, 0 		#this will be our return value (0 = no collision, 1 = collision)
	addi $t7, $t7, -1284 	#the min position for the rocket to be
	addi $t6, $s1, 12 	#getting the index of the right most pixel of the rocket
	blt $t6, $t7, NEXT_COLLISION_DETECTION
	
	addi $t7, $t7, 8 	#the max position for the rocket to be
	bgt $t6, $t7, NEXT_COLLISION_DETECTION
	
	#collision detected
	li $t8, 1
	j DONE_STAR_COLLISION
	
	NEXT_COLLISION_DETECTION:
	addi $t7, $t7, -8 	#the min position for the rocket to be
	addi $t6, $s1, 0 	#getting the index of the left most pixel of the rocket
	
	blt $t6, $t7, DONE_STAR_COLLISION
	
	addi $t7, $t7, 8 	#the max position for the rocket to be
	
	bgt $t6, $t7, DONE_STAR_COLLISION
	
	#collision detected
	li $t8, 1
	j DONE_STAR_COLLISION
	
	DONE_STAR_COLLISION:
		#pushing the return value onto the stack
		addi $sp, $sp, -4
		sw $t8, 0($sp)
		
		jr $ra
		

CLEAR:
 	#loading the frameBuffer
 	la $t0, frameBuffer
 	
	li $t1, 0x20000 	#save other corner pixel
	li $t2, BLACK_COLOUR 	#loading black colour
	
	COLOURING:
		sw $t2, 0($t0)
		addi $t0, $t0, 4 	#advance to next pixel
		addi $t1, $t1, -1 	#decrement number of pixels
		bnez $t1, COLOURING 	#repete until we have no more pixels to colour 
	
	jr $ra
 	
 
DRAW_STAR:
	#loading the frameBuffer
 	la $t0, frameBuffer
 	
 	#pop starting index
 	lw $t1, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop clear value
 	lw $t2, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop star colour
 	lw $t4, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#if the clear value is 1 then we set the colours to black otherwise we set them to the proper colours
 	IF_CLEAR_STAR: bne $t2, 1, ELSE_CLEAR_STAR 
 		li $t2, BLACK_COLOUR 	#loading the black colour
 		li $t3, BLACK_COLOUR 	#loading the black colour
 		
 		j CONTINUE_DRAW_STAR
 		
 	ELSE_CLEAR_STAR:
 		addi $t2, $t4, 0 		#loading the darker yellow colour
 		li $t3, LIGHT_STAR_COLOUR 	#loading the lighter yellow colour
 	
 CONTINUE_DRAW_STAR:	
 	add $t0, $t0, $t1 	#starting at proper index
 	sw $t2, 0($t0) 
 	
 	addi $t0, $t0, -260 	#moving up a row and out 1 pixel
 	sw $t2, 0($t0)
 	sw $t3, 4($t0)
 	sw $t2, 8($t0)
 	addi $t0, $t0, -252 	#moving up a row and in 1 pixel
 	sw $t2, 0($t0)
 	
 	jr $ra
 	
DRAW_METEOR:
 	
 	#loading the frameBuffer
 	la $t0, frameBuffer
 	
 	#pop starting index
 	lw $t1, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop clear value
 	lw $t2, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop colour of the meteor
 	lw $t3, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#if the clear value is 1 then we set the colours to black otherwise we set them to the proper colours
 	IF_CLEAR_METEOR: bne $t2, 1, ELSE_CLEAR_METEOR
 		li $t2, BLACK_COLOUR 	#loading the black colour
 		li $t3, BLACK_COLOUR 	#loading the black colour
 		
 		j CONTINUE_DRAW_METEOR
 		
 	ELSE_CLEAR_METEOR:
 		move $t2, $t3			#loading the filler colour
 		li $t3, LIGHT_METEOR_COLOUR 	#loading the lighter grey colour
 	
 CONTINUE_DRAW_METEOR:
 	add $t0, $t0, $t1 	#adding to get to our desired location
 	
 	#starting from the bottom of the metor we'll begin to draw it
 	sw $t2, 0($t0) 
 	sw $t3, 4($t0)
 	sw $t3, 8($t0)
 	sw $t3, 12($t0)
 	
 	addi $t0, $t0, -264 	#moving up a row and further 2 pixels
 	
 	sw $t2, 0($t0) 
 	sw $t2, 4($t0) 
 	sw $t2, 8($t0) 
 	sw $t2, 12($t0) 
 	sw $t2, 16($t0)
 	sw $t2, 20($t0)
 	sw $t3, 24($t0)
 	
 	addi $t0, $t0, -256 	#moving up a row
 	
 	sw $t3, 0($t0) 
 	sw $t2, 4($t0) 
 	sw $t2, 8($t0) 
 	sw $t2, 12($t0) 
 	sw $t2, 16($t0)
 	sw $t2, 20($t0)
 	sw $t2, 24($t0)
 	sw $t2, 28($t0)
 	
 	addi $t0, $t0, -256 	#moving up a row
 	
 	sw $t3, 0($t0) 
 	sw $t2, 4($t0) 
 	sw $t2, 8($t0) 
 	sw $t3, 12($t0) 
 	sw $t2, 16($t0)
 	sw $t2, 20($t0)
 	sw $t2, 24($t0)
 	sw $t2, 28($t0)
 	
 	addi $t0, $t0, -252 	#moving up a row and in one pixel
 	
 	sw $t3, 0($t0) 
 	sw $t3, 4($t0) 
 	sw $t3, 8($t0) 
 	sw $t2, 12($t0)
 	sw $t2, 16($t0)
 	sw $t2, 20($t0)
 	
 	jr $ra
 
DRAW_HEART:
 	#loading the frameBuffer
 	la $t0, frameBuffer
 
 	#pop starting index 
 	lw $t1, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop clear value
 	lw $t2, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack

 	add $t0, $t0, $t1 	#adding to get to our desired location
 	
 	#if the clear value is 1 then we set the colours to black otherwise we set them to the proper colours
 	IF_CLEAR_HEART: bne $t2, 1, ELSE_CLEAR_HEART
 		li $t1, BLACK_COLOUR 	#loading the black colour
 		j CONTINUE_DRAW_HEART
 		
 	ELSE_CLEAR_HEART:
 		li $t1, HEART_COLOUR 	#loading our pink colour
 	
 CONTINUE_DRAW_HEART:
 	sw $t1, 0($t0)
 	sw $t1, 8($t0) 
 	
 	addi $t0, $t0, 252 		#moving down a row and out one
 	
 	sw $t1, 0($t0) 
 	sw $t1, 4($t0) 
 	sw $t1, 8($t0) 
 	sw $t1, 12($t0) 
 	sw $t1, 16($t0) 
 	
 	addi $t0, $t0, 260 		#moving down a row and in one
 	
 	sw $t1, 0($t0) 
 	sw $t1, 4($t0) 
 	sw $t1, 8($t0)
 	
 	addi $t0, $t0, 260 		#moving down a row and in one
 	
 	sw $t1, 0($t0) 
 	
 	jr $ra
 
DRAW_ROCKET:
 	#loading the frameBuffer
 	la $t0, frameBuffer
 
 	#pop starting index 
 	lw $t1, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop clear value
 	lw $t2, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#if the clear value is 1 then we set the colours to black otherwise we set them to the proper colours
 	IF_CLEAR_ROCKET: bne $t2, 1, ELSE_CLEAR_ROCKET
 		li $t2, BLACK_COLOUR 	#loading the black colour
 		li $t3, BLACK_COLOUR 	#loading the black colour
 		
 		j CONTINUE_DRAW_ROCKET
 		
 	ELSE_CLEAR_ROCKET:
 		li $t2, RED_ROCKET_COLOUR 	#loading our red colour
 		li $t3, BLUE_ROCKET_COLOUR 	#loading our blue colour
 	
 CONTINUE_DRAW_ROCKET:
 	
 	add $t0, $t0, $t1 	#adding to get to our desired location
 	
 	#drawing the rocket
 	sw $t3, 0($t0) 		#drawing the bottom legs of the rocket
 	sw $t3, 16($t0) 	#drawing the bottom legs of the rocket
 	
 	addi $t0, $t0, -256 	#moving up a row
 	
 	sw $t3, 0($t0) 		#drawing the bottom legs of the rocket
 	sw $t2, 4($t0) 		#drawing the bottom body of the rocket
 	sw $t2, 8($t0) 		#drawing the bottom body of the rocket
 	sw $t2, 12($t0) 	#drawing the bottom body of the rocket
 	sw $t3, 16($t0) 	#drawing the bottom legs of the rocket
 	
 	addi $t0, $t0, -252 	#moving up a row and in one pixel
 	
 	sw $t2, 0($t0) 		#drawing the body of the rocket
 	sw $t3, 4($t0) 		#drawing the body of the rocket
 	sw $t2, 8($t0) 		#drawing the body of the rocket
 	
 	addi $t0, $t0, -256 	#moving up a row
 	
 	sw $t2, 0($t0) 		#drawing the body of the rocket
 	sw $t3, 4($t0) 		#drawing the body of the rocket
 	sw $t2, 8($t0) 		#drawing the body of the rocket
 	
 	addi $t0, $t0, -256 	#moving up a row
 	
 	sw $t2, 0($t0) 		#drawing the body of the rocket
 	sw $t2, 4($t0) 		#drawing the body of the rocket
 	sw $t2, 8($t0) 		#drawing the body of the rocket
 	
 	addi $t0, $t0, -252 	#moving up a row and in one
 	
 	sw $t2, 0($t0) 		#drawing the body of the rocket
 	
 	jr $ra
 
 DRAW_LINE:
	#loading the frameBuffer
 	la $t0, frameBuffer
 	
 	#pop starting index 
 	lw $t1, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop of how long the line is
 	lw $t2, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	#pop off colour
 	lw $t3, 0($sp)
 	addi $sp, $sp, 4 	#adding to get the next element of the stack
 	
 	add $t0, $t0, $t1 	#adding to ge to the desired location
 	
 	DRAWING:
		sw $t3, 0($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, -1 	#decrement number of pixels
		bnez $t2, DRAWING 	#repete until we have no more pixels to colour  
	
	jr $ra
 
 START_BACKGROUND:
 
	MAKING_EARTH:
	
	#DRAWING FIRST EARTH LINE
		li $t0, 7940 			#4*(31*64+1) - our index of the line
		li $t2, LIGHT_EARTH_COLOUR 	#loading forest green colour
		li $t1, 62 			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
	#DRAWING SECOND EARTH LINE
		li $t0, 7688 			#4*(30*64+2) - our index of the line
		li $t2, LIGHT_EARTH_COLOUR 	#loading forest green colour
		li $t1, 60 			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
	
	#DRAWING THRID EARTH LINE
		li $t0, 7440 			#4*(29*64+4) - our index of the line
		li $t2, LIGHT_EARTH_COLOUR 	#loading forest green colour
		li $t1, 56 			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE	
		
	#DRAWING FOURTH EARTH LINE
		li $t0, 7192 			#4*(28*64+6) - our index of the line
		li $t2, LIGHT_EARTH_COLOUR 	#loading forest green colour
		li $t1, 52 			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE	
		
	#DRAWING FIFTH EARTH LINE
		li $t0, 6952 			#4*(27*64+10) - our index of the line
		li $t2, LIGHT_EARTH_COLOUR 	#loading forest green colour
		li $t1, 44 			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
	#ADDING DIMENSION
		#First darker line
		li $t0, 7976 			#4*(31*64+10) - our index of the line
		li $t2, DARK_EARTH_COLOUR 	#loading darker forest green colour
		li $t1, 28 			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
		#Second darker line
		li $t0, 7604 			#4*(29*64+45) - our index of the line
		li $t2, DARK_EARTH_COLOUR 	#loading darker forest green colour
		li $t1, 10			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
		#Third darker line
		li $t0, 6992 			#4*(27*64+20) - our index of the line
		li $t2, DARK_EARTH_COLOUR 	#loading darker forest green colour
		li $t1, 20 			#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
	MAKING_ROCKET:
		li $t0, 7540 #4*(29*64+29) - our index of the line
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $zero, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_ROCKET	
	
	MAKING_METEORS: 
	#Drawing the meteors in the beginning background
	
	#Meteor 1
		li $t0, 4392 		#4*(17*64+10) - our index of the line
		
		#pushing the colour of the meteor on the stack
		addi $sp, $sp, -4 
		li $t1, DARK_METEOR_COLOUR1
		sw $t1, 0($sp)
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $zero, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_METEOR
		
	#Meteor 2
		li $t0, 1952 #4*(7*64+40) - our index of the line
		
		#pushing the colour of the meteor on the stack
		addi $sp, $sp, -4 
		li $t1, DARK_METEOR_COLOUR3
		sw $t1, 0($sp)
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $zero, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_METEOR
		
	#Meteor 3
		li $t0, 5596 		#4*(21*64+55) - our index of the line
		
		#pushing the colour of the meteor on the stack
		addi $sp, $sp, -4 
		li $t1, DARK_METEOR_COLOUR2
		sw $t1, 0($sp)
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $zero, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_METEOR
	
	STARTING_TITLE:
		la $t0, frameBuffer #loading the address of our frame buffer
		
		addi $t0, $t0, 792  	#4*(3*64+6) - our index of the the first word
		
#Drawing MOON
		li $t1, WORD_COLOUR #loading our blue colour
		
	#First row of MOON
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		sw $t1, 12($t0) 
		sw $t1, 16($t0)
		
		sw $t1, 28($t0) 
		sw $t1, 44($t0) 
		sw $t1, 56($t0) 
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Second row of MOON
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		sw $t1, 8($t0) 
		sw $t1, 12($t0)
		sw $t1, 16($t0)
		
		sw $t1, 24($t0) 
		sw $t1, 32($t0)
		 
		sw $t1, 40($t0) 
		sw $t1, 48($t0)
		
		sw $t1, 56($t0) 
		sw $t1, 60($t0)
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Third row of MOON
		sw $t1, 0($t0) 
		sw $t1, 8($t0) 
		sw $t1, 16($t0)
		 
		sw $t1, 24($t0)
		sw $t1, 32($t0)
		
		sw $t1, 40($t0) 
		sw $t1, 48($t0)
		 
		sw $t1, 56($t0) 
		sw $t1, 60($t0)
		sw $t1, 64($t0) 
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fourth row of MOON
		sw $t1, 0($t0) 
		sw $t1, 16($t0)
		 
		sw $t1, 24($t0)
		sw $t1, 32($t0)
		
		sw $t1, 40($t0) 
		sw $t1, 48($t0)
		 
		sw $t1, 56($t0) 
		sw $t1, 64($t0) 
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fifth row of MOON
		sw $t1, 0($t0) 
		sw $t1, 16($t0)
		 
		sw $t1, 28($t0)
		sw $t1, 44($t0)
		
		sw $t1, 56($t0) 
		sw $t1, 68($t0)
		
#Drawing ROCKET
		addi $t0, $t0, 1280   	#moving down 5 rows
		addi $t0, $t0, 56   	#moving over 56
		
	#First row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		sw $t1, 8($t0)
		 
		sw $t1, 20($t0)
		
		sw $t1, 36($t0) 
		sw $t1, 40($t0) 
		
		sw $t1, 48($t0) 
		sw $t1, 56($t0)
		
		sw $t1, 68($t0) 
		sw $t1, 72($t0) 
		sw $t1, 76($t0)
		 
		sw $t1, 84($t0)
		sw $t1, 88($t0) 
		sw $t1, 92($t0) 
		sw $t1, 96($t0)
		sw $t1, 100($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Second row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 8($t0) 
		
		sw $t1, 16($t0) 
		sw $t1, 24($t0)
		
		sw $t1, 32($t0)
		
		sw $t1, 48($t0) 
		sw $t1, 56($t0)
		 
		sw $t1, 68($t0)
		 
		sw $t1, 92($t0)
		
		addi $t0, $t0, 256  	#moving down a row and to the beginning index
		
	#Third row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		
		sw $t1, 16($t0) 
		sw $t1, 24($t0)
		
		sw $t1, 32($t0)
		
		sw $t1, 48($t0) 
		sw $t1, 52($t0)
		 
		sw $t1, 68($t0) 
		sw $t1, 72($t0)
		
		sw $t1, 92($t0) 
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fourth row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 8($t0)
		 
		sw $t1, 16($t0)
		sw $t1, 24($t0)
		
		sw $t1, 32($t0) 
		
		sw $t1, 48($t0)
		sw $t1, 56($t0)
		 
		sw $t1, 68($t0) 
		
		sw $t1, 92($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fifth row of ROCLKET
		sw $t1, 0($t0) 
		sw $t1, 8($t0)
		 
		sw $t1, 20($t0)
		
		sw $t1, 36($t0)
		sw $t1, 40($t0)
		 
		sw $t1, 48($t0)
		sw $t1, 60($t0)
		
		sw $t1, 68($t0)
		sw $t1, 72($t0)
		sw $t1, 76($t0)
		
		sw $t1, 92($t0)
	
	j STARTING_GAME_POSITION
	
CLEAR_START_BACKGROUND:
 
	CLEAR_EARTH:
	
	#DRAWING FIRST EARTH LINE
		li $t0, 7940 		#4*(31*64+1) - our index of the line
		li $t2, BLACK_COLOUR 	#loading forest green colour
		li $t1, 62 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
	#DRAWING SECOND EARTH LINE
		li $t0, 7688 		#4*(30*64+2) - our index of the line
		li $t2, BLACK_COLOUR 	#loading forest green colour
		li $t1, 60 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
	
	#DRAWING THRID EARTH LINE
		li $t0, 7440 		#4*(29*64+4) - our index of the line
		li $t2, BLACK_COLOUR 	#loading forest green colour
		li $t1, 56 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE	
		
	#DRAWING FOURTH EARTH LINE
		li $t0, 7192 		#4*(28*64+6) - our index of the line
		li $t2, BLACK_COLOUR 	#loading forest green colour
		li $t1, 52 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE	
		
	#DRAWING FIFTH EARTH LINE
		li $t0, 6952 		#4*(27*64+10) - our index of the line
		li $t2, BLACK_COLOUR 	#loading forest green colour
		li $t1, 44 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
	#ADDING DIMENSION
		#First darker line
		li $t0, 7976 		#4*(31*64+10) - our index of the line
		li $t2, BLACK_COLOUR 	#loading darker forest green colour
		li $t1, 28 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
		#Second darker line
		li $t0, 7604 		#4*(29*64+45) - our index of the line
		li $t2, BLACK_COLOUR 	#loading darker forest green colour
		li $t1, 10 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
		#Third darker line
		li $t0, 6992 		#4*(27*64+20) - our index of the line
		li $t2, BLACK_COLOUR 	#loading darker forest green colour
		li $t1, 20 		#loading row of pixels 
		
		#pushing the colour onto the stack
		addi $sp, $sp, -4 
		sw $t2, 0($sp)
		
		#pushing the width of the line onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index of the line onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		#Calling DRAW_LINE to draw out first line
		jal DRAW_LINE
		
	li $t1, CLEAR_VALUE #for the clear value
	
	CLEAR_START_ROCKET:
		li $t0, 7540 	#4*(29*64+29) - our index of the line
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_ROCKET	
	
	CLEAR_START_METEORS: 
	#Drawing the meteors in the beginning background
	
	#Meteor 1
		li $t1, CLEAR_VALUE #for the clear value
		li $t0, 4392 	#4*(17*64+10) - our index of the line
		
		#pushing the colour of the meteor on the stack
		addi $sp, $sp, -4 
		li $t2, DARK_METEOR_COLOUR1
		sw $t2, 0($sp)
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_METEOR
		
	#Meteor 2
		li $t1, CLEAR_VALUE #for the clear value
		li $t0, 1952 	#4*(7*64+40) - our index of the line
		
		#pushing the colour of the meteor on the stack
		addi $sp, $sp, -4 
		li $t2, DARK_METEOR_COLOUR1
		sw $t2, 0($sp)
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_METEOR
		
	#Meteor 3
		li $t1, CLEAR_VALUE #for the clear value
		li $t0, 5596 	#4*(21*64+55) - our index of the line
		
		#pushing the colour of the meteor on the stack
		addi $sp, $sp, -4 
		li $t2, DARK_METEOR_COLOUR1
		sw $t2, 0($sp)
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $t1, 0($sp)
		
		#pushing the starting index onto the stack
		addi $sp, $sp, -4 
		sw $t0, 0($sp)
		
		jal DRAW_METEOR
	
	CLEAR_STARTING_TITLE:
		la $t0, frameBuffer 	#loading the address of our frame buffer
		
		addi $t0, $t0, 792   	#4*(3*64+6) - our index of the the first word
		
#Drawing MOON
		li $t1, BLACK_COLOUR 	#loading our black colour
		
	#First row of MOON
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		sw $t1, 12($t0) 
		sw $t1, 16($t0)
		
		sw $t1, 28($t0) 
		sw $t1, 44($t0) 
		sw $t1, 56($t0) 
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Second row of MOON
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		sw $t1, 8($t0) 
		sw $t1, 12($t0)
		sw $t1, 16($t0)
		
		sw $t1, 24($t0) 
		sw $t1, 32($t0)
		 
		sw $t1, 40($t0) 
		sw $t1, 48($t0)
		
		sw $t1, 56($t0) 
		sw $t1, 60($t0)
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
			
	#Third row of MOON
		sw $t1, 0($t0) 
		sw $t1, 8($t0) 
		sw $t1, 16($t0)
		 
		sw $t1, 24($t0)
		sw $t1, 32($t0)
		
		sw $t1, 40($t0) 
		sw $t1, 48($t0)
		 
		sw $t1, 56($t0) 
		sw $t1, 60($t0)
		sw $t1, 64($t0) 
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fourth row of MOON
		sw $t1, 0($t0) 
		sw $t1, 16($t0)
		 
		sw $t1, 24($t0)
		sw $t1, 32($t0)
		
		sw $t1, 40($t0) 
		sw $t1, 48($t0)
		 
		sw $t1, 56($t0) 
		sw $t1, 64($t0) 
		sw $t1, 68($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fifth row of MOON
		sw $t1, 0($t0) 
		sw $t1, 16($t0)
		 
		sw $t1, 28($t0)
		sw $t1, 44($t0)
		
		sw $t1, 56($t0) 
		sw $t1, 68($t0)
		
#Drawing ROCKET
		addi $t0, $t0, 1280   	#moving down 5 rows
		addi $t0, $t0, 56   	#moving over 56
		
	#First row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		sw $t1, 8($t0)
		 
		sw $t1, 20($t0)
		
		sw $t1, 36($t0) 
		sw $t1, 40($t0) 
		
		sw $t1, 48($t0) 
		sw $t1, 56($t0)
		
		sw $t1, 68($t0) 
		sw $t1, 72($t0) 
		sw $t1, 76($t0)
		 
		sw $t1, 84($t0)
		sw $t1, 88($t0) 
		sw $t1, 92($t0) 
		sw $t1, 96($t0)
		sw $t1, 100($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Second row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 8($t0) 
		
		sw $t1, 16($t0) 
		sw $t1, 24($t0)
		
		sw $t1, 32($t0)
		
		sw $t1, 48($t0) 
		sw $t1, 56($t0)
		 
		sw $t1, 68($t0)
		 
		sw $t1, 92($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Third row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 4($t0) 
		
		sw $t1, 16($t0) 
		sw $t1, 24($t0)
		
		sw $t1, 32($t0)
		
		sw $t1, 48($t0) 
		sw $t1, 52($t0)
		 
		sw $t1, 68($t0) 
		sw $t1, 72($t0)
		
		sw $t1, 92($t0) 
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fourth row of ROCKET
		sw $t1, 0($t0) 
		sw $t1, 8($t0)
		 
		sw $t1, 16($t0)
		sw $t1, 24($t0)
		
		sw $t1, 32($t0) 
		
		sw $t1, 48($t0)
		sw $t1, 56($t0)
		 
		sw $t1, 68($t0) 
		
		sw $t1, 92($t0)
		
		addi $t0, $t0, 256   	#moving down a row and to the beginning index
		
	#Fifth row of ROCLKET
		sw $t1, 0($t0) 
		sw $t1, 8($t0)
		 
		sw $t1, 20($t0)
		
		sw $t1, 36($t0)
		sw $t1, 40($t0)
		 
		sw $t1, 48($t0)
		sw $t1, 60($t0)
		
		sw $t1, 68($t0)
		sw $t1, 72($t0)
		sw $t1, 76($t0)
		
		sw $t1, 92($t0)
	
	j CLEARED
 
 END: 
 	
 	CLEARING_FAIL:
 		#clearing the hearts
 		li $t5, 492
 		li $t4, CLEAR_VALUE
 		
 		CLEAR_HEARTS_START:
			beqz $s3, END_CLEARING_HEARTS_START 	#if there are no more hearts to draw we end drawing
		
			#pushing the clear value onto the stack
			addi $sp, $sp, -4 
			sw $t4, 0($sp)
	
			#pushing the index onto the stack
			addi $sp, $sp, -4 
			sw $t5, 0($sp)
	
			jal DRAW_HEART
	
			addi $t5, $t5, -24
			addi $s3, $s3, -1 #decrement our counter
			j CLEAR_HEARTS_START
		
		END_CLEARING_HEARTS_START:
		
		#clear the rocket clear then start
		
		#pushing the clear value onto the stack
		addi $sp, $sp, -4 
		sw $t4, 0($sp)
	
		#pushing the index onto the stack
		addi $sp, $sp, -4 
		sw $s1, 0($sp)
		
		jal DRAW_ROCKET
 		
 		#clearing everything else
 		la $a0, meteors
 		la $a1, in_meteors
 		
 		li $t8, NUM_METEORS
 		
 		CLEAR_METEOR_LOOP:
 			beqz $t8, FAIL_SCREEN
 			
 			lw $t7, 0($a1)
 			beqz, $t7, END_CLEAR_LOOP
 			
 			CLEARING_METEOR_FAIL:
 				#clear the current position the meteor is at
 				lw $t7, 0($a0)
 				
 			#clearing the star no matter what because it's less lines than checking if there is a star
 			CLEARING_STAR_LOOP:
 				#pushing the star colour onto the stack (doesn't matter here)
				addi $sp, $sp, -4 
				li $t6, DARK_STAR_COLOUR
				sw $t6, 0($sp)
			
				li $t6, CLEAR_VALUE
				#pushing the clear value on the stack
				addi $sp, $sp, -4
				sw $t6, 0($sp)
			
				lw $t7, 0($a0) 
				addi $t7, $t7, -1280
				#pushing the index of the star on the stack
				addi $sp, $sp, -4
				sw $t7, 0($sp)
				
				jal DRAW_STAR
 				
 				#clearing the meteors
 				lw $t7, 0($a0)
 				
 				#pushing the colour of the meteor on the stack
				addi $sp, $sp, -4 
				li $t6, DARK_METEOR_COLOUR1
				sw $t6, 0($sp)
 				
				#pushing the clear value onto the stack
				addi $sp, $sp, -4 
				li $t6, CLEAR_VALUE
				sw $t6, 0($sp)
	
				#pushing the starting index onto the stack
				addi $sp, $sp, -4 
				sw $t7, 0($sp)
	
				jal DRAW_METEOR
				
 				
 		END_CLEAR_LOOP:
 			addi $a0, $a0, 4
 			addi $a1, $a1, 4
 			addi $t8, $t8, -4
 			
 			j CLEAR_METEOR_LOOP
 			
 	
 	FAIL_SCREEN:
 		la $t0, frameBuffer 		#loading the address of our frame buffer
 		
 		li $t1, WHITE_COLOUR 		#loading our black colour
 		li $t2, BLUE_ROCKET_COLOUR 	#loading our black colour
 		
 		addi $t0, $t0, 1900 		#4*(7*64+27)
 		
 		sw $t2, 2312($t0)
 		
 		sw $t2, 2336($t0)
 		sw $t2, 2592($t0)
 		sw $t2, 2848($t0)
 		
 		sw $t2, 2568($t0)
 		
 		sw $t2, 3844($t0)
 		sw $t2, 4100($t0)
 		
 		sw $t2, 3356($t0)
 		
 		sw $t2, 4380($t0)
 		
 		sw $t2, 5124($t0)
 		sw $t2, 5380($t0)
 		
 		sw $t2, 5376($t0)
 		
 		sw $t1, 0($t0)
 		sw $t1, 4($t0)
 		sw $t1, 8($t0)
 		sw $t1, 12($t0)
 		sw $t1, 16($t0)
 		sw $t1, 20($t0)
 		sw $t1, 24($t0)
 		sw $t1, 28($t0)
 		
 		sw $t1, 284($t0)
 		sw $t1, 288($t0)
 		
 		sw $t1, 548($t0)
 		
 		sw $t1, 808($t0)
 		sw $t1, 812($t0)
 		sw $t1, 1068($t0)
 		sw $t1, 1324($t0)
 		
 		sw $t1, 1584($t0)
 		sw $t1, 1840($t0)
 		
 		sw $t1, 2100($t0)
 		sw $t1, 2356($t0)
 		sw $t1, 2612($t0)
 		sw $t1, 2868($t0)
 		sw $t1, 3124($t0)
 		
 		sw $t1, 3120($t0)
 		sw $t1, 3376($t0)
 		sw $t1, 3632($t0)
 		
 		sw $t1, 3628($t0)
 		sw $t1, 3884($t0)
 		
 		sw $t1, 3880($t0)
 		sw $t1, 4132($t0)
 		
 		sw $t1, 4384($t0)
 		sw $t1, 4380($t0)
 		
 		sw $t1, 4632($t0)
 		sw $t1, 4628($t0)
 		sw $t1, 4624($t0)
 		sw $t1, 4620($t0)
 		sw $t1, 4616($t0)
 		sw $t1, 4612($t0)
 		sw $t1, 4608($t0)
 		
 		sw $t1, 4352($t0)
 		sw $t1, 4348($t0)
 		
 		sw $t1, 4092($t0)
 		sw $t1, 4088($t0)
 		
 		sw $t1, 3832($t0)
 		sw $t1, 3576($t0)
 		
 		sw $t1, 3592($t0)
 		sw $t1, 3596($t0)
 		sw $t1, 3600($t0)
 		sw $t1, 3856($t0)
 		sw $t1, 3860($t0)
 		sw $t1, 3864($t0)
 		sw $t1, 3864($t0)
 		
 		sw $t1, 3320($t0)
 		
 		sw $t1, 3060($t0)
 		sw $t1, 2804($t0)
 		sw $t1, 2548($t0)
 		sw $t1, 2292($t0)
 		sw $t1, 2036($t0)
 		sw $t1, 1780($t0)
 		
 		sw $t1, 1792($t0)
 		sw $t1, 1796($t0)
 		sw $t1, 1800($t0)
 		
 		sw $t1, 1816($t0)
 		sw $t1, 1820($t0)
 		sw $t1, 1824($t0)
 		sw $t1, 1828($t0)
 		
 		sw $t1, 1524($t0)
 		sw $t1, 1268($t0)
 		
 		sw $t1, 1016($t0)
 		sw $t1, 760($t0)
 		
 		sw $t1, 764($t0)
 		sw $t1, 508($t0)
 		
 		sw $t1, 256($t0)
 	
 	li $v0, 10 # terminate the program gracefully 
 	syscall

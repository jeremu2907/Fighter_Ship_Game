##########################################################################################
#		   			Ship v Alien
#			use W,A,S,D to move up, left, down, and right
#	    	 You only need to protect your ship's core, don't get hit there
#		    You can hold down the key to continously move the ship
#
#
#
##########################################################################################
#	Instructions:			#
#	Set pixel to 4x4		#
#	Set display to 256x512  	#
#	Set Address to Heap		#
#	Connect to mips then run	#
########################################

.eqv WIDTH 64
.eqv HEIGHT 128
.eqv MEM 0x10040000

.eqv	GREY	0x00cccccc
.eqv	GREY0	0x00444444 
.eqv	BLACK	0x00000000
.eqv	RED	0x00FFCCCC
.eqv	CRIM	0x00730000
.eqv	MRED	0x00fc5f21
.eqv	FIRE	0x00f7da65
.eqv	BLUE	0x00CCCCFF
.eqv	WHITE	0x00FFFFFF
.eqv	YELLOW	0x00e3fccc
.eqv	CYAN	0x00aaDDDD
.eqv	SBLUE	0x0006afd2
.eqv	PURP	0x00350f59

.data
#spaceship Struct	#xOrigin 4, yOrigin 4, colorMain 4, colorSec 4
ship0:	.word		0,0,SBLUE,CYAN
ship1:	.word		0,0,MRED,FIRE
ship2:	.word		0,0,GREY0,PURP
ship3:	.word		0,0,GREY,YELLOW
ship4:	.word		0,0,CRIM,BLACK
#projectile
proj:	.word		0,0
#asteroid Struct	#xOrigin 4, yOrigin 4, number hit, speed, COLOR
en1:	.word		50,10,0, 1, WHITE
en2:	.word		5,25,0, 1, WHITE
en3:	.word		40,35,0, 1, WHITE
en4:	.word		11,45,0, 1, WHITE
#dialogs
Opening:	.asciiz	"Greetings,\nAre you ready to eliminate the Skulls unit?\nChoose your ship for battle!\n[1] Blue Hawk\n[2] Fiery Phoenix\n[3] Dark Blaze\n[4] Merciful Angel\n[5] Crimson Vengeance"
Score:		.asciiz "You Scored: "
ErrorColor:	.asciiz "Choose your battleship again!"
winStatement:	.asciiz "You defeated the Skulls unit!"
loseStatement:	.asciiz "You died in battle, but valiantly"
.text
#############################################
#Setting initial environment variable########
#############################################
main:	
	#blackout screen
	jal BlackOutScreen
	
	#Open Welcome Dialog
	li $v0, 51
	la $a0, Opening
	syscall
	beq $a0, 1, chooseBLUE
	beq $a0, 2, choosePHOE
	beq $a0, 3, chooseFIRE
	beq $a0, 4, chooseANGE
	beq $a0, 5, chooseCRIM
	#user input choice
	beq $a1, -1, invalidCol
	beq $a1, -3, invalidCol
	beq $a1, -2, exitNoScore
	
	invalidCol:
	li $v0, 55
	la $a0, ErrorColor
	syscall
	j main
	
	#User choose ship
	#$s1 will be global register for ship position and data
	chooseBLUE:
		la $s1, ship0
		j setPositionShip
	choosePHOE:
		la $s1, ship1
		j setPositionShip
	chooseFIRE:
		la $s1, ship2
		j setPositionShip
	chooseANGE:
		la $s1, ship3
		j setPositionShip
	chooseCRIM:
		la $s1, ship4
		j setPositionShip
		
	#Calculate original position of ship
	setPositionShip:
		li $t0, WIDTH
		sra $t0, $t0, 1
		li $t1, HEIGHT
		addi $t1, $t1, -25
		sw $t0, 0($s1)
		sw $t1, 4($s1)
	
	#These two are global reg
	li $s0, 0		#counter
	li $s2, 0		#cycle
#############################################
#Setting initial environment variable########
#############################################

bigLoop:
#if player reaches this level, they win though --- good luck
beq $s2, 10000, winGame

#############################################################################
#get interval for projectile#################################################
################This makes it look like a lazer##############################

beq $s0, 0, newProj	#making a new projectile, the old one is out of screen
j contProj

#Get the origin of the ship, minus one y then store to the projectile origin
newProj:
	la $t4, proj		#load address of projectile
	lw $t3, 0($s1)
	sw $t3, 0($t4)
	lw $t3, 4($s1)
	addi $t3, $t3, -1
	sw $t3, 4($t4)
	
#Once the projectile object is created, every cycle minus
#projecttile y by one then blackout -> draw
contProj:
	
	la $t4, proj	#load data of proj
	lw $a0, 0($t4)
	lw $a1, 4($t4)
	jal drawProjectileBlack
	#if the y is at 0, stop drawing (Prevent leak)
	blt $a1, 1, noAdd
	addi $a1, $a1, -1
	j contToDraw
	noAdd:
		remove:		#remove artifacts of previous projectiles
			jal drawProjectileBlack
			j test
	contToDraw:	#drawing current position of projectile
	sw $a0, 0($t4)
	sw $a1, 4($t4)
	li $a2, BLUE
	jal drawProjectile
	
########Check if projectile hits##########
##########################################
test:
	la $a0, en2
	la $a1, proj
	jal checkProj
	la $a0, en1
	jal checkProj
	la $a0, en3
	jal checkProj
	la $a0, en4
	jal checkProj
########Check if projectile hits##########
##########################################



#################################################################
#Space ship movement#############################################
#################################################################

mainLoop:
#get input
lw $t2, 0xffff0000
beq $t2, 0, contMain
lw $t3, 0xffff0004
beq $t3, 32, exit	#if space is pushed, exit program

#if w,a,s,d is clicked blacken the current location of the ship, then move on
lw $a0, 0($s1)
lw $a1, 4($s1)
li $a2, BLACK
jal drawShipBlack

	#Adjusting the coordinate of the ship
	beq $t3, 97, left
	beq $t3, 100, right
	beq $t3, 119, up
	beq $t3, 115, down
	j contMain
	#Player choosing which direction to move
	left:
		addi $t0, $t0, -1
		blt $t0, 7, fixLeft
		j contMain
	right:
		addi $t0, $t0, 1
		bgt $t0, 56, fixRight
		j contMain
	up:
		addi $t1, $t1, -2
		blt $t1, 20, fixTop
		j contMain
	down:
		addi $t1, $t1, 2
		bgt $t1, 115, fixBot
		j contMain
		
		fixLeft:
			li $t0, 7
			j contMain
		fixRight:
			li $t0, 56
			j contMain
		fixTop:
			li $t1, 20
			j contMain
		fixBot:
			li $t1, 115
			j contMain
			
	#main drawing branch
	contMain:
	#drawing ship
	move $a0, $t0
	move $a1, $t1
	lw $a2, 8($s1)
	jal drawShip
	sw $a0, 0($s1)
	sw $a1, 4($s1)

##############################################################
#Check ship core collision ###################################
##############################################################
	la $a0, en1
	jal checkShip
	beq $v1, 999, loseGame
	la $a0, en2
	jal checkShip
	beq $v1, 999, loseGame
	la $a0, en3
	jal checkShip
	beq $v1, 999, loseGame
	la $a0, en4
	jal checkShip
	beq $v1, 999, loseGame
##############################################################
#Check ship core collision ###################################
##############################################################

#################################################################
#Enemy#############################################
#################################################################
	#Once played long enough, game get harder
	blt $s2, 250, speed1
	beq $s0, 64, drawEnemyS
	beq $s0, 63, drawEnemyM
	beq $s0, 62, drawEnemyF
	beq $s0, 61, drawEnemyX
	
	#Initial speed
	speed1:
		beq $s0, 128, drawEnemyS
		beq $s0, 127, drawEnemyM
		beq $s0, 126, drawEnemyF
		beq $s0, 125, drawEnemyX
	j skipEnemy
	#Select which enemy to draw
	drawEnemyS:
	la $t4, en2
	j ENcont
	drawEnemyX:
	la $t4, en4
	j ENcont
	drawEnemyM:
	la $t4, en1
	j ENcont
	drawEnemyF:
	la $t4, en3
	j ENcont
	
	ENcont:
	lw $a0, 0($t4)
	lw $a1, 4($t4)
	jal drawEnemyBlack	#Erase previous enemy postion
	
       	#If Enemy is hit enough times, increase their speed 
        #And respawn them
	lw $t7, 8($t4)		
		#Comment this block to introduce random rouge spawning
		move $t9, $t7
		#Comment this block to introduce random rouge spawning
	div $t7, $t7, 17
	mfhi $t7
	bne $t7, 16, noAddSpeedEn
		#Comment this block to introduce random rouge spawning
			#Add Times Hit
			addi, $t9, $t9, 1
			sw $t9, 8($t4)
		#Comment this block to introduce random rouge spawning
		#Add Speed
		lw $t7, 12($t4)
		addi $t7, $t7, 1
		sw $t7, 12($t4)
		#Reset Enemy 
		j EnemyAdjust
	#Avoid speeding up too much, capping at 4px per cycle / 8px per cycle (hard)
	noAddSpeedEn:
	lw $t7, 12($t4)
	blt $t7, 4, noFixSpeed
		li $t7, 4
	#Move Enemy down
	noFixSpeed:
	add $a1, $a1, $t7
	bge $a1, 128, EnemyAdjust
	j EnemyCont
	#Reset Enemy position to top of display
	EnemyAdjust:
		li $v0, 42
		li $a1, 50
		syscall
		li $a1, -13
		addi $a0, $a0, 2
	EnemyCont:
	sw $a0, 0($t4)
	sw $a1, 4($t4)
	lw $a2, 16($t4)
	jal drawEnemy
	
	

#################################################################
#Enemy#############################################
#################################################################

skipEnemy:
addi $s0, $s0, 1
beq $s0, 129, intervalReset
j bigLoop
intervalReset:
#Reset Cycle and update
li $s0, 0
addi $s2, $s2, 1		
j bigLoop

#################################################################
#Space ship movement#############################################
#################################################################
winGame:
	li $v0, 55
	li $a1, 100
	la $a0, winStatement
	syscall
	j exit
loseGame:
	li $v0, 55
	li $a1, 100
	la $a0, loseStatement
	syscall
	j exit

exit:
	
	#Calculate score, summing all scores from enemies
	la $t9, en1
	lw $t9, 8($t9)
	addi $a1, $t9, 0
	la $t9, en2
	lw $t9, 8($t9)
	add $a1,$a1, $t9
	la $t9, en3
	lw $t9, 8($t9)
	add $a1,$a1, $t9
	la $t9, en4
	lw $t9, 8($t9)
	add $a1,$a1, $t9
	div $a1, $a1, 100
	mflo $a1
	#Display score
	li $v0, 56
	la $a0, Score
	syscall
	
	exitNoScore:
	li $v0, 10
	syscall
	
###############################################
#		Macros			       #
###############################################

.macro draw
	mul $t9, $t7, WIDTH
	add $t9, $t9, $t8
	mul $t9, $t9, 4
	add $t9, $t9, MEM
	sw $a2, ($t9)
.end_macro

.macro addX
	addi $t8, $t8, 1
.end_macro

.macro subX
	addi $t8, $t8, -1
.end_macro

.macro addY
	addi $t7, $t7, 1
.end_macro

.macro subY
	addi $t7, $t7, -1
.end_macro


####################################################
#This function checks if the ship hits the##########
#####Enemy##########################################
checkShip:
#	$a0 enemy
	lw $t6, 0($a0)	#Get OriginX enemy
	lw $t7, 0($s1)	#Get Originx Ship
	addi $t6, $t6, -3
	blt $t7, $t6, checkShipDone
	addi $t6, $t6, 12
	bgt $t7, $t6, checkShipDone
	
	lw $t6, 4($a0)	#Get OriginY enemy
	lw $t7, 4($s1)	#Get OriginY Ship
	addi $t7, $t7, 6
	blt $t7, $t6, checkShipDone
	addi $t7, $t7, -6
	bgt $t7, $t6, checkShipDone
	
	
		li $v1, 999 
		jr $ra
	
checkShipDone:
li $v1, 0
jr $ra
	

####################################################
#This function checks if the projectile hits the####
#####Enemy##########################################

checkProj:
#	$a0 &enemy	$a1 &projectile
	lw $t7, 4($s1)		#Get origin Y of ship
	lw $t8, 4($a0)		#Get origin Y of Enemy
	bgt $t8, $t7, ignoreHit	#Ignore if ship is on top of enemy
	lw $t7, 0($a0)		#Get origin X of enemy
	addi $t7, $t7, 8
	lw $t9, 0($a1)		#Get origin X of projectile
	bgt $t9, $t7, ignoreHit	#Ignore if projectile is out side of X bound
	addi $t7, $t7, -10	
	blt $t9, $t7, ignoreHit#Ignore if projectile is out side of X bound
	addi $t8, $t8, 12
	lw $t9, 4($a1)		#Get origin Y of projectile
	bgt $t9, $t8, ignoreHit
		li $t8, RED
		sw $t8, 16($a0)
		lw $t8, 8($a0)
		addi $t8, $t8, 1
		sw $t8, 8($a0)
		j checkDone


ignoreHit:
li $v0, 0
li $t8, WHITE
sw $t8, 16($a0)
jr $ra

checkDone:
li $v0, 1
jr $ra

####################################################
#This function draws a single pixel#################
####################################################
drawFunc:
#	$a0 = x		$a1 = y		$a2 = color
#	Location (x,y) in address is	s1 = address = MEM + 4(x + y WIDTH)
	
	#move $t6, $a2
	move $t8, $a0
	move $t7, $a1
	draw
	
	jr $ra 


####################################################
#This function draws the space ship#################
####################################################
drawShip:
	#	$a0 = x		$a1 = y		$a2 = color
#	Location (x,y) in address is	s1 = address = MEM + 4(x + y WIDTH)
	
	#move from a reg to t
	move $t8, $a0
	move $t7, $a1

#	$t8 = x		$t7 = y	
	li $t6, 0	#outer loop counter
	lw $t5, 12($s1)
	lw $t4, 8($s1)
	drawShipLoop:
		beq $t6, 12, drawShipReturn
		beq $t6, 0, row01
		beq $t6, 1, row01
		beq $t6, 2, row2
		beq $t6, 3, row3
		beq $t6, 4, row4
		beq $t6, 5, row5
		beq $t6, 6, row5
		beq $t6, 7, row7
		beq $t6, 8, row8
		beq $t6, 9, row9
		beq $t6, 10,row10
		j drawShipReturn
		
		row01:
			draw
			j drawShipLoopCont
		row2:	
			subX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopCont
		row3:	
			subX
			subX
			draw
			addX
			move $a2, $t5
			draw
			move $a2, $t4
			addX
			draw
			j drawShipLoopCont
		row4:
			addi $t8, $t8, -5
			draw
			addX
			addX
			draw
			addX
			draw
			addX
			move $a2, $t5
			draw
			move $a2, $t4
			addX
			draw
			addX
			draw
			addX
			addX
			draw
			j drawShipLoopCont
		row5:
			addi $t8, $t8, -8
			draw
			addX
			draw
			addX
			draw
			addX
			move $a2, $t5
			draw
			addX
			draw
			addX
			draw
			move $a2, $t4
			addX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopCont
		row8:
			subX
		row7:	
			addi $t8, $t8, -9
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			move $a2, $t5
			draw
			addX
			draw
			addX
			draw
			addX
			move $a2, $t4
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopCont
		row9:
			addi $t8, $t8, -11
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopCont
		row10:
			addi $t8, $t8, -12
			draw
			addX
			draw
			addX
			addX
			addX
			addX
			draw
			addX
			draw
			addY
			draw
			subY
			addX
			draw
			addX
			addX
			addX
			addX
			draw
			addX
			draw
			j drawShipLoopCont

	drawShipLoopCont:
		addY
		addi $t6, $t6, 1
		j drawShipLoop
	
	drawShipReturn:
		jr $ra 
	
####################################################
#This function blackout the space ship##############
####################################################

drawShipBlack:
	#	$a0 = x		$a1 = y		$a2 = color
#	Location (x,y) in address is	s1 = address = MEM + 4(x + y WIDTH)
	
	#move from a reg to t
	move $t8, $a0
	move $t7, $a1
	li $a2, BLACK

#	$t8 = x		$t7 = y	
	li $t6, 0	#outer loop counter
	drawShipLoopBlack:
		beq $t6, 12, drawShipReturnBlack
		beq $t6, 0, row01Black
		beq $t6, 1, row01Black
		beq $t6, 2, row2Black
		beq $t6, 3, row3Black
		beq $t6, 4, row4Black
		beq $t6, 5, row5Black
		beq $t6, 6, row5Black
		beq $t6, 7, row7Black
		beq $t6, 8, row8Black
		beq $t6, 9, row9Black
		beq $t6, 10,row10Black
		j drawShipReturnBlack
		
		row01Black:
			draw
			j drawShipLoopContBlack
		row2Black:	
			subX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopContBlack
		row3Black:	
			subX
			subX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopContBlack
		row4Black:
			addi $t8, $t8, -5
			draw
			addX
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			addX
			draw
			j drawShipLoopContBlack
		row5Black:
			addi $t8, $t8, -8
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopContBlack
		row8Black:
			subX
		row7Black:
			addi $t8, $t8, -9
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopContBlack
		row9Black:
			addi $t8, $t8, -11
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			addX
			draw
			j drawShipLoopContBlack
		row10Black:
			addi $t8, $t8, -12
			draw
			addX
			draw
			addX
			addX
			addX
			addX
			draw
			addX
			draw
			addY
			draw
			subY
			addX
			draw
			addX
			addX
			addX
			addX
			draw
			addX
			draw
			j drawShipLoopContBlack

	drawShipLoopContBlack:
		addY
		addi $t6, $t6, 1
		j drawShipLoopBlack
	
	drawShipReturnBlack:
		jr $ra 


####################################################
#This function blacks out the projectile############
####################################################
drawProjectileBlack:
	#	$a0 = x		$a1 = y		$a2 = color
	#	Location (x,y) in address is	s1 = address = MEM + 4(x + y WIDTH)
	move $t8, $a0
	move $t7, $a1
	li $a2, BLACK
	draw
	addY
	draw
	addY
	draw
	addY
	draw
	addY
	draw
	addY
	draw
	jr $ra
	
####################################################
#This function draws the lazer w/ gradient##########
####################################################
drawProjectile:
	#	$a0 = x		$a1 = y		$a2 = color
	#	Location (x,y) in address is	s1 = address = MEM + 4(x + y WIDTH)
	move $t8, $a0
	move $t7, $a1
	draw
	addY
	draw
	addY
	addi $a2, $a2, -0x00002222
	draw
	addY
	addi $a2, $a2, -0x00002222
	draw
	addY
	addi $a2, $a2, -0x00002222
	draw
	addY
	addi $a2, $a2, -0x00002222
	draw
	
	jr $ra

####################################################
#This function draws Enemy##########################
####################################################
drawEnemy:
	move $t8, $a0
	move $t7, $a1
	move $t6, $a2
	
	draw
	addX
	draw
	addX
	addX
	addX
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addi $t8, $t8, 6
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -8
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	draw
	addX
	li $a2, BLACK
	draw
	addX
	draw
	addX
	move $a2, $t6
	draw
	addX
	draw
	addX
	draw
	addX
	li $a2, BLACK
	draw
	addX
	draw
	addX
	move $a2, $t6
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	draw
	addX
	draw
	addX
	li $a2, BLACK
	draw
	addX
	draw
	addX
	move $a2, $t6
	draw
	addX
	li $a2, BLACK
	draw
	addX
	draw
	addX
	move $a2, $t6
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	li $a2, BLACK
	draw
	addX
	move $a2, $t6
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	li $a2, BLACK
	draw
	addX
	move $a2, $t6
	draw
	
	addi $t8, $t8, -8
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyCont
	draw
	addX
	addX
	draw
	addX
	addX
	draw
	addX
	addX
	draw

	drawEnemyCont:	
	jr $ra

####################################################
#This function Blacks Enemy#########################
####################################################
drawEnemyBlack:
	li $a2, BLACK
	move $t8, $a0
	move $t7, $a1
	
	
	draw
	addX
	draw
	addX
	addX
	addX
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addi $t8, $t8, 6
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -8
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -10
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	
	addi $t8, $t8, -8
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	addX
	draw
	
	addi $t8, $t8, -6
	addY
	beq $t7, 127, drawEnemyContBlack
	draw
	addX
	addX
	draw
	addX
	addX
	draw
	addX
	addX
	draw

	drawEnemyContBlack:	
	jr $ra

BlackOutScreen:
	li $t8, 0
	li $t7, 0
	li $a2, BLACK
	li $a0, 0
	li $a1, 0
	
	loopOut:
		beq $t7, 129, exitloopOut
		loopIn:
			beq $t8, 65, exitloopIn
			draw
			addi $t8, $t8, 1
			j loopIn
		exitloopIn:
		li $t8, 0
		addi $t7, $t7, 1
		j loopOut
		
	exitloopOut:
	jr $ra
		
		
		

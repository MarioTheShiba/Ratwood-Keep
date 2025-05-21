// LORE : The Martial Artist has perfected a beautiful union of the arcyne with martial arts, and under Noc's gaze, he teaches the weak to defend themselves. 

// some defines to make things work


/mob/living/carbon/get_bodypart(zone)
	if(!zone)
		zone = BODY_ZONE_CHEST
	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		if(bodypart.body_zone == zone)
			return bodypart
		for(var/subzone in bodypart.subtargets)
			if(subzone != zone)
				continue
			return bodypart

// utility abilities

/obj/effect/proc_holder/spell/self/ryusui
	name = "Paws of Flowing Water"
	desc = "Imbue your fists with the technique of the Flowing Water."
	human_req = TRUE
	miracle = FALSE
	charge_max = 99999 MINUTES // one time self-buff.
	invocation = "Paws of Flowing Water."
	invocation_type = "none"
	movement_interrupt = FALSE
	sound = 'sound/magic/ryusuibuff.ogg'

/obj/effect/proc_holder/spell/self/ryusui/cast(list/targets, mob/living/user)
		user.change_stat("strength", 6)
		user.change_stat("speed",3)
		user.change_stat("perception",3)



/obj/effect/proc_holder/spell/self/ryubreath
	// pretty insane self heal, fickle to balance, i'm keeping it at 30 seconds for now.
	name = "Steady Breath"
	desc = "Steady your breathing, allowing the flowing waters to heal your wounds."
	human_req = TRUE
	miracle = FALSE
	charge_max = 25 SECONDS
	invocation = "Aaahh..."
	invocation = "none"
	movement_interrupt = FALSE


/obj/effect/proc_holder/spell/self/ryubreath/cast(list/targets, mob/living/user)
	user.visible_message(span_warning("[user] steadies their breath, the flowing water technique rejuvinating them slightly!"), span_notice("I steady my breath, rejuvinating myself..."))
	user.adjustBruteLoss(-35)
	user.adjustFireLoss(-25)
	user.adjustToxLoss(-10)
	user.blood_volume = min(user.blood_volume+90, BLOOD_VOLUME_NORMAL)
	user.heal_wounds(35)
	// heals most common damage types + gives some blood.

// combat abilities

/obj/effect/proc_holder/spell/invoked/ryuflowfist
	name = "Flowing Fist" // basic fisting ability, although very strong.
	desc = "Suddenly strike your enemy's vitals, knocking the air out of them, and dealing damage."
	human_req = TRUE
	range = 1
	miracle = FALSE
	charge_max = 25 SECONDS
	movement_interrupt = FALSE
	invocation = "Haha!"
	invocation_type = "shout"


/obj/effect/proc_holder/spell/invoked/ryuflowfist/cast(list/targets, mob/living/user)
	if(isliving(targets[1]))
		var/mob/living/carbon/target = targets[1]
		var/obj/item/bodypart/BPC = target.get_bodypart(BODY_ZONE_CHEST)
		target.visible_message(span_warningbig("[target] is striked by a heavy blow!"), span_userdanger("I feel the air escape my lungs as I am punched in my chest!"))
		playsound(target, 'sound/magic/bigfist2.ogg', 50)
		target.apply_damage(rand(15,45), BRUTE, BPC)
		target.adjustOxyLoss(35)
		target.blind_eyes(1)
		target.blur_eyes(5)
		target.Knockdown(5)
		yeet(target)
		user.say("Get up, come on!")
		return TRUE
	return FALSE

/obj/effect/proc_holder/spell/invoked/ryuflowfist/proc/yeet(mob/living/target, mob/living/user)
	if(!target || !user || !isliving(target))
		return
	var/dir = get_dir(user, target)
	var/turf/throw_target = get_edge_target_turf(get_turf(target), dir)
	
	if (throw_target)
		target.throw_at(throw_target, 2, 4)


/obj/effect/proc_holder/spell/invoked/ryurock
	name = "Paws of Flowing Water - Crushed Rock" // this is a parry/counter, with big damage and knockdown + fracture.
	desc = "Enter a defensive stance, countering all melee attacks upon you."
	human_req = TRUE
	range = 0
	miracle = FALSE
	movement_interrupt = FALSE
	invocation = "Ryūsui...!"
	invocation_type = "shout"
	sound = 'sound/magic/deathcounter.ogg'
	antimagic_allowed = TRUE
	charge_max = 45 SECONDS
	var/counter_active = FALSE
	var/duration = 70 // how long you're gonna counter people for.


/obj/effect/proc_holder/spell/invoked/ryurock/cast(list/targets, mob/living/user)
	if (!isliving(user))
		return FALSE

	var/mob/living/M = user

	if (M.anti_magic_check(TRUE, TRUE))
		return FALSE // we can't counter if they use anti-magic! we are using magic fists.

	if (counter_active)
		M.show_message(span_warning("Already performing this move."))
		return FALSE

	M.visible_message(
		span_warning("[M] enters a brutal defensive stance."),
		span_notice("You steady yourself...")
		)

	counter_active = TRUE


	// we countering all melee attacks with this one!! :speaking_head: :fire: . except for ranged attacks!! those hurttttt.
	RegisterSignal(M, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW, COMSIG_ATOM_ATTACK_ANIMAL, COMSIG_MOB_ATTACK_HAND), PROC_REF(on_attacked))
	RegisterSignal(M, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	addtimer(CALLBACK(src, PROC_REF(disable_ryurock), M), duration)
	return TRUE

/obj/effect/proc_holder/spell/invoked/ryurock/proc/on_attacked(mob/victim, mob/living/attacker)
	SIGNAL_HANDLER
	if (!isliving(attacker))
		return
	// this is where the fun begins.
	var/turf/target_turf = get_step(get_turf(attacker), attacker.dir) // grabs location of attacker
	attacker.Immobilize(1.5 SECONDS) // ouch, you got caught.
	var/obj/item/bodypart/BPC = attacker.get_bodypart(BODY_ZONE_CHEST)
	victim.forceMove(target_turf)
	attacker.visible_message(span_warning("[victim] quickly sidesteps [attacker]'s your attack, however they do get hit by it in the process!"))
	sleep(5)
	victim.say("Dumbass!")
	sleep(10)
	playsound(victim, 'sound/magic/bigfist1.ogg', 50)
	attacker.apply_damage(rand(35,75), BRUTE, BPC)
	BPC.add_wound(/datum/wound/fracture/chest)
	attacker.visible_message(span_warningbig("[victim] launches a crushing blow to [attacker]'s your chest, launching you back, a sickening crunch heard!"))
	yeett(attacker)
	attacker.Knockdown(15)
	victim.say("What's wrong, chest feeling heavy?")


/obj/effect/proc_holder/spell/invoked/ryurock/proc/yeett(target)
	if(isliving(target))
		var/atom/throw_target = get_edge_target_turf(src, get_dir(src, target)) //shoutout radiant for the help
		var/mob/living/L = target
		if(L)
			L.throw_at(throw_target, 5, 4)



/obj/effect/proc_holder/spell/invoked/ryurock/proc/on_attackby(atom/target, obj/item/weapon, mob/attacker)
	on_attacked(target, attacker)


/obj/effect/proc_holder/spell/invoked/ryurock/proc/disable_ryurock(mob/user)
	UnregisterSignal(user, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW, COMSIG_ATOM_ATTACK_ANIMAL, COMSIG_MOB_ATTACK_HAND, COMSIG_PARENT_ATTACKBY))
	user.visible_message(
		span_warning("[user] returns to their normal stance."),
		span_notice("You relax your stance.")
	)
	counter_active = FALSE

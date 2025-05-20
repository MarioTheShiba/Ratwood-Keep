// LORE : The Martial Artist has perfected a beautiful union of the arcyne with martial arts, and under Noc's gaze, he teaches the weak to defend themselves. 

// some defines to make things work

/mob/living/throw_at(atom/target, range, speed, mob/thrower, spin=4, diagonals_first = 0, datum/callback/callback, force)
	stop_pulling()

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
	invocation = "slowly moves their hands in an intricate manner, a blue water-like aura following them."
	invocation_type = "emote"
	movement_interrupt = FALSE
	sound = 'sound/magic/ryusuibuff.ogg'

/obj/effect/proc_holder/spell/self/ryusui/cast(list/targets, mob/living/user)
	if(user.mind)
		user.mind.adjust_skillrank(/datum/skill/combat/unarmed, 6, TRUE)
		user.mind.adjust_skillrank(/datum/skill/combat/wrestling, 5, TRUE)
		user.change_stat("strength", 3)
		user.change_stat("speed",1)
		user.change_stat("perception",2)



/obj/effect/proc_holder/spell/self/ryubreath
	// pretty insane self heal, fickle to balance, i'm keeping it at 30 seconds for now.
	name = "Paws of Flowing Water - Steady Breath"
	desc = "Steady your breathing, allowing the flowing waters to heal your wounds."
	human_req = TRUE
	miracle = FALSE
	charge_max = 25 SECONDS
	invocation = "breathes softly, steadying their breath..."
	invocation = "emote"
	movement_interrupt = FALSE


/obj/effect/proc_holder/spell/self/ryubreath/cast(list/targets, mob/living/user)
	user.visible_message(span_warning("[user] steadies their breath, the flowing water technique rejuvinating them slightly!"), span_notice("I steady my breath, rejuvinating myself..."))
	user.adjustBruteLoss(-20)
	user.adjustFireLoss(-25)
	user.adjustToxLoss(-10)
	user.blood_volume = min(user.blood_volume+60, BLOOD_VOLUME_NORMAL)
	user.heal_wounds(25)
	// heals most common damage types + gives some blood.

// combat abilities

/obj/effect/proc_holder/spell/invoked/ryuflowfist
	name = "Paws of Flowing Water - Flowing Fist" // basic fisting ability, although very strong.
	desc = "Suddenly strike your enemy's vitals, knocking the air out of them, and dealing damage."
	human_req = TRUE
	range = 1
	miracle = FALSE
	charge_max = 35 SECONDS
	movement_interrupt = FALSE
	invocation = "Kaihō-ken!"
	invocation_type = "shout"


/obj/effect/proc_holder/spell/invoked/ryuflowfist/cast(list/targets, mob/living/user)
	if(isliving(targets[1]))
		var/mob/living/carbon/target = targets[1]
		var/turf/shove = get_step(get_turf(user), user.dir)
		target.visible_message(span_info("[target] is striked by a heavy blow!"), span_userdanger("I feel the air escape my lungs as I am punched!"))
		playsound(target, 'sound/magic/bigfist2.ogg', 50)
		target.adjustBruteLoss(35)
		target.adjustOxyLoss(10)
		target.blind_eyes(1)
		target.blur_eyes(5)
		target.Knockdown(5)
		target.throw_at(shove, 3, 5)
		target.Immobilize(5)
		return TRUE
	return FALSE

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
	charge_max = 60 SECONDS
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
		span_warning("[M] enters a defensive stance."),
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
	var/turf/shove = get_step(get_turf(victim), victim.dir)
	var/turf/target_turf = get_step(get_turf(attacker), attacker.dir) // grabs location of attacker
	attacker.Immobilize(1.5 SECONDS) // ouch, you got caught.
	var/obj/item/bodypart/BPC = attacker.get_bodypart(BODY_ZONE_CHEST)
	victim.forceMove(target_turf)
	attacker.visible_message(span_warning("[victim] quickly sidesteps [attacker]'s attack, however they do get hit by it in the process!"))
	sleep(5)
	victim.say("Gansai-ken!")
	sleep(10)
	playsound(victim, 'sound/magic/bigfist1.ogg', 50)
	attacker.apply_damage(rand(25,45), BRUTE, BPC)
	BPC.add_wound(/datum/wound/fracture/chest)
	victim.visible_message(span_warningbig("[victim] launches a crushing blow to [attacker]'s chest, launching them back, a sickening crunch heard!"))
	attacker.throw_at(shove, 3, 4)
	attacker.Knockdown(15)
	attacker.Immobilize(25)



/obj/effect/proc_holder/spell/invoked/ryurock/proc/on_attackby(atom/target, obj/item/weapon, mob/attacker)
	on_attacked(target, attacker)


/obj/effect/proc_holder/spell/invoked/ryurock/proc/disable_ryurock(mob/user)
	UnregisterSignal(user, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW, COMSIG_ATOM_ATTACK_ANIMAL, COMSIG_MOB_ATTACK_HAND, COMSIG_PARENT_ATTACKBY))
	user.visible_message(
		span_warning("[user] returns to their normal stance."),
		span_notice("You relax your stance.")
	)
	counter_active = FALSE

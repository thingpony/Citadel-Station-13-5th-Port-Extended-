//Xenobio control console
/mob/camera/aiEye/remote/xenobio
	visible_icon = 1
	icon = 'icons/obj/abductor.dmi'
	icon_state = "camera_target"


/mob/camera/aiEye/remote/xenobio/setLoc(var/t)
	var/area/new_area = get_area(t)
	if(new_area && new_area.name == "Slime Biology Lab" || istype(new_area, /area/toxins/xenobiology ))
		return ..()
	else
		return

/obj/machinery/computer/camera_advanced/xenobio
	name = "Slime management console"
	desc = "A computer used for remotely handling slimes."
	networks = list("SS13")
	off_action = new/datum/action/innate/camera_off/xenobio
	var/datum/action/innate/slime_place/slime_place_action = new
	var/datum/action/innate/slime_pick_up/slime_up_action = new
	var/datum/action/innate/feed_slime/feed_slime_action = new
	var/datum/action/innate/monkey_recycle/monkey_recycle_action = new

	var/list/stored_slimes = list()
	var/max_slimes = 5
	var/monkeys = 0

	icon_screen = "slime_comp"
	icon_keyboard = "rd_key"

/obj/machinery/computer/camera_advanced/xenobio/CreateEye()
	eyeobj = new /mob/camera/aiEye/remote/xenobio()
	eyeobj.loc = get_turf(src)
	eyeobj.origin = src
	eyeobj.visible_icon = 1
	eyeobj.icon = 'icons/obj/abductor.dmi'
	eyeobj.icon_state = "camera_target"

/obj/machinery/computer/camera_advanced/xenobio/GrantActions(mob/living/carbon/user)
	off_action.target = user
	off_action.Grant(user)

	jump_action.target = user
	jump_action.Grant(user)

	slime_up_action.target = src
	slime_up_action.Grant(user)

	slime_place_action.target = src
	slime_place_action.Grant(user)

	feed_slime_action.target = src
	feed_slime_action.Grant(user)

	monkey_recycle_action.target = src
	monkey_recycle_action.Grant(user)


/obj/machinery/computer/camera_advanced/xenobio/attack_hand(mob/user)
	if(!ishuman(user)) //AIs using it might be weird
		return
	return ..()

/datum/action/innate/camera_off/xenobio/Activate()
	if(!target || !ishuman(target))
		return
	var/mob/living/carbon/C = target
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/origin = remote_eye.origin
	C.remote_view = 0
	origin.current_user = null
	origin.jump_action.Remove(C)
	//All of this stuff below could probably be a proc for all advanced cameras, only the action removal needs to be camera specific
	remote_eye.user = null
	if(C.client)
		C.client.perspective = MOB_PERSPECTIVE
		C.client.eye = src
		C.client.images -= remote_eye.user_image
		for(var/datum/camerachunk/chunk in remote_eye.visibleCameraChunks)
			C.client.images -= chunk.obscured
	C.remote_control = null
	C.unset_machine()
	src.Remove(C)


/datum/action/innate/slime_place
	name = "Place Slimes"
	button_icon_state = "slime_down"

/datum/action/innate/slime_place/Activate()
	if(!target || !ishuman(owner))
		return
	var/mob/living/carbon/human/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		for(var/mob/living/simple_animal/slime/S in X.stored_slimes)
			S.loc = remote_eye.loc
			S.visible_message("[S] warps in!")
			X.stored_slimes -= S

/datum/action/innate/slime_pick_up
	name = "Pick up Slime"
	button_icon_state = "slime_up"

/datum/action/innate/slime_pick_up/Activate()
	if(!target || !ishuman(owner))
		return
	var/mob/living/carbon/human/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		for(var/mob/living/simple_animal/slime/S in remote_eye.loc)
			if(X.stored_slimes.len >= X.max_slimes)
				break
			if(!S.ckey)
				if(S.buckled)
					S.Feedstop(silent=1)
				S.visible_message("[S] vanishes in a flash of light!")
				S.loc = X
				X.stored_slimes += S


/datum/action/innate/feed_slime
	name = "Feed Slimes"
	button_icon_state = "monkey_down"

/datum/action/innate/feed_slime/Activate()
	if(!target || !ishuman(owner))
		return
	var/mob/living/carbon/human/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		if(X.monkeys >= 1)
			var/mob/living/carbon/monkey/food = new /mob/living/carbon/monkey(remote_eye.loc)
			food.LAssailant = C
			X.monkeys --
			owner << "[X] now has [X.monkeys] monkeys left."


/datum/action/innate/monkey_recycle
	name = "Recycle Monkeys"
	button_icon_state = "monkey_up"

/datum/action/innate/monkey_recycle/Activate()
	if(!target || !ishuman(owner))
		return
	var/mob/living/carbon/human/C = owner
	var/mob/camera/aiEye/remote/xenobio/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/xenobio/X = target

	if(cameranet.checkTurfVis(remote_eye.loc))
		for(var/mob/living/carbon/monkey/M in remote_eye.loc)
			if(M.stat)
				M.visible_message("[M] vanishes as they are reclaimed for recycling!")
				X.monkeys += 0.2
				qdel(M)

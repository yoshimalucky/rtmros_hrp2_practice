#!/usr/bin/env roseus
(load "package://hrpsys_ros_bridge_tutorials/euslisp/hrp2w-interface.l")

(defun preparation
  ()
  (hrp2w-init)
  (objects *hrp2w*)
  (send *hrp2w* :reset-manip-pose)
  (send *hrp2w* :fix-leg-to-coords (make-coords))
  (send *irtviewer* :draw-objects)
  )

(defun move-robot
  ()
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun clicked-pt-cb (msg)
  (setq *msg* msg)
  (setq *torso-co* (send (car (send *hrp2w* :torso)) :copy-worldcoords))
  (setq *clicked-pt* (make-coords))
  (send *clicked-pt* :locate (float-vector (* 1000 (send *msg* :point :x))
                                           (* 1000 (send *msg* :point :y))
                                           (* 1000 (send *msg* :point :z))))
  (setq *ik-target* (send *torso-co* :transform *clicked-pt*))
  (setq *rarm-end* (send *hrp2w* :rarm :end-coords :copy-worldcoords))
  (send *rarm-end* :locate (send *ik-target* :pos) :world)
  (send *rarm-end* :translate #f(0 0 0))

  ;; go-pos for *vmax*
  (send *vmax* :go-pos-relative-unsafe
        (- (elt (send *rarm-end* :pos) 0) 300)
        (elt (send *rarm-end* :pos) 1)
        0 ;; no twist angle
        (* 10 (norm (send *rarm-end* :pos))))
  (send *vmax* :wait-interpolation)

  (send *hrp2w* :rarm :inverse-kinematics *rarm-end*
        :rotation-axis nil
        :debug-view t :torso nil
        :link-list (send *hrp2w* :link-list
                         (send *hrp2w* :rarm :end-coords :parent)
                         (car (send *hrp2w* :torso :links))))
  )
(setq *msg* nil)

(preparation)
(format t "Press ENTER to reset-manip-pose!~%")
(read-line)
(move-robot)
(ros::roseus "clicked_point_ik")
(ros::subscribe "clicked_point" geometry_msgs::PointStamped #'clicked-pt-cb)

(do-until-key
 (ros::spin-once)
 )
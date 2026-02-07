local ragdollHinges = Instance.new("Folder")
ragdollHinges.Name = "RagdollHinges"

local r15 = Instance.new("Folder")
r15.Name = "R15"

local ankle = Instance.new("HingeConstraint")
ankle.Name = "Ankle"
ankle.LimitsEnabled = true
ankle.UpperAngle = 0
ankle.Parent = r15

local default = Instance.new("BallSocketConstraint")
default.Name = "Default"
default.LimitsEnabled = true
default.TwistLimitsEnabled = true
default.TwistLowerAngle = -15
default.TwistUpperAngle = 15
default.UpperAngle = 20
default.Parent = r15

local elbow = Instance.new("HingeConstraint")
elbow.Name = "Elbow"
elbow.LimitsEnabled = true
elbow.LowerAngle = 0
elbow.UpperAngle = 135
elbow.Parent = r15

local hip = Instance.new("BallSocketConstraint")
hip.Name = "Hip"
hip.LimitsEnabled = true
hip.TwistLimitsEnabled = true
hip.TwistLowerAngle = -3
hip.TwistUpperAngle = 3
hip.UpperAngle = 40
hip.Parent = r15

local knee = Instance.new("HingeConstraint")
knee.Name = "Knee"
knee.LimitsEnabled = true
knee.LowerAngle = -135
knee.UpperAngle = -10
knee.Parent = r15

local neck = Instance.new("BallSocketConstraint")
neck.Name = "Neck"
neck.LimitsEnabled = true
neck.MaxFrictionTorque = 78480
neck.TwistLimitsEnabled = true
neck.TwistLowerAngle = -40
neck.TwistUpperAngle = 40
neck.UpperAngle = 0
neck.Parent = r15

local root = Instance.new("RigidConstraint")
root.Name = "Root"
root.Parent = r15

local shoulder = Instance.new("BallSocketConstraint")
shoulder.Name = "Shoulder"
shoulder.LimitsEnabled = true
shoulder.TwistLimitsEnabled = true
shoulder.TwistLowerAngle = -30
shoulder.TwistUpperAngle = 30
shoulder.UpperAngle = 30
shoulder.Parent = r15

local waist = Instance.new("BallSocketConstraint")
waist.Name = "Waist"
waist.LimitsEnabled = true
waist.TwistLimitsEnabled = true
waist.TwistLowerAngle = -1
waist.TwistUpperAngle = 1
waist.UpperAngle = 15
waist.Parent = r15

local wrist = Instance.new("HingeConstraint")
wrist.Name = "Wrist"
wrist.LimitsEnabled = true
wrist.LowerAngle = -20
wrist.UpperAngle = 20
wrist.Parent = r15

r15.Parent = ragdollHinges

local r6 = Instance.new("Folder")
r6.Name = "R6"

local default1 = Instance.new("BallSocketConstraint")
default1.Name = "Default"
default1.TwistLimitsEnabled = true
default1.TwistLowerAngle = -15
default1.TwistUpperAngle = 15
default1.UpperAngle = 20
default1.Parent = r6

local hip1 = Instance.new("BallSocketConstraint")
hip1.Name = "Hip"
hip1.LimitsEnabled = true
hip1.TwistLimitsEnabled = true
hip1.TwistLowerAngle = -40
hip1.TwistUpperAngle = 40
hip1.UpperAngle = 90
hip1.Parent = r6

local neck1 = Instance.new("BallSocketConstraint")
neck1.Name = "Neck"
neck1.LimitsEnabled = true
neck1.TwistLimitsEnabled = true
neck1.TwistLowerAngle = -30
neck1.TwistUpperAngle = 30
neck1.UpperAngle = 0
neck1.Parent = r6

local root1 = Instance.new("RigidConstraint")
root1.Name = "Root"
root1.Parent = r6

local shoulder1 = Instance.new("BallSocketConstraint")
shoulder1.Name = "Shoulder"
shoulder1.LimitsEnabled = true
shoulder1.TwistLimitsEnabled = true
shoulder1.TwistLowerAngle = -40
shoulder1.TwistUpperAngle = 40
shoulder1.UpperAngle = 90
shoulder1.Parent = r6

r6.Parent = ragdollHinges

return ragdollHinges

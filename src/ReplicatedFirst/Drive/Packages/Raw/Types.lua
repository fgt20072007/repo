export type Body <R> = {
	--// Metadata
	__index: Body <R>,

	_resetImpulse: (Body <R>) -> (),
	_setError: (Body <R>, dt: number, err: number) -> (),
	_setImpulse: (Body <R>, dt: number) -> (),

	_stepBefore: (Body <R>, dt: number) -> (),
	_stepAfter: (Body <R>, dt: number) -> (),

	_replace: (Body <R>) -> (),
	
	--// Properties
	Inertia: number,
	
	--// State
	Rotation: number,
	AngularVelocity: number,
	
	--// Solver
	AccumulatedImpulse: number,
	Impulse: number,
	Error: number,
} & R

export type Constraint <R> = {
	--// Metadata
	__index: Constraint <R>,
	
	_resetImpulse: (Constraint <R>) -> (),
	_setError: (Constraint <R>, dt: number, err: number) -> (),
	_setImpulse: (Constraint <R>, dt: number) -> (),

	_stepBefore: (Constraint <R>, dt: number) -> (),
	_stepAfter: (Constraint <R>, dt: number) -> (),
	
	--// Properties
	Attachments: {Body <unknown>},

	--// Solver
	AccumulatedImpulse: number,
	Impulse: number,
	Error: number,
} & R

export type SQI = {
	__index: SQI,
	
	_oddeven: number,

	ITERATIONS: number,
	SUBSTEPS: number,
	ERROR_SCALING: number,

	Solve: (self: SQI, dt: number, Components: {Constraint <unknown>}) -> (),
	Step: (self: SQI, dt: number, Components: {Constraint <unknown>}) -> (),
}

return nil
class_name OpticData
extends AttachmentTypeData

## Magnification multiplier. If variable zoom is enabled, this field has no effect.
@export var magnification: float
#@export reticle_style: ReticleStyle
@export var variable_zoom := false
@export var min_magnification: float
@export var max_magnification: float

@export var spread_multiplier: float
#@export var range_multiplier: float # maybe implement?

@export var reticle_style: ReticleStyle

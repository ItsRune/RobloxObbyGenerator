export type settings = {
	output: { fileName: string, xmlKind: boolean },
	difficulties: { string },
	mode: "Obby",
	sections: number, -- Stage count
	Publish: { experienceId: number?, placeId: number? },
	applyVersioningToPreventRegeneration: boolean?,
	showDebugMessages: boolean?,
}

return nil

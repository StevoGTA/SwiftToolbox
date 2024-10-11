//
//  AWSRegion.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/22/24.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: AWSRegion
public struct AWSRegion : Hashable {

	// MARK: Properties
	static	public	let	afSouth1 = AWSRegion(tag: "af-south-1", name: "Africa (Cape Town)")

	static	public	let	apEast1 = AWSRegion(tag: "ap-east-1", name: "Asia Pacific (Hong Kong)")
	static	public	let	apNortheast1 = AWSRegion(tag: "ap-northeast-1", name: "Asia Pacific (Tokyo)")
	static	public	let	apNortheast2 = AWSRegion(tag: "ap-northeast-2", name: "Asia Pacific (Seoul)")
	static	public	let	apNortheast3 = AWSRegion(tag: "ap-northeast-3", name: "Asia Pacific (Osaka)")
	static	public	let	apSouth1 = AWSRegion(tag: "ap-south-1", name: "Asia Pacific (Mumbai)")
	static	public	let	apSouth2 = AWSRegion(tag: "ap-south-2", name: "Asia Pacific (Hyderabad)")
	static	public	let	apSoutheast1 = AWSRegion(tag: "ap-southeast-1", name: "Asia Pacific (Singapore)")
	static	public	let	apSoutheast2 = AWSRegion(tag: "ap-southeast-2", name: "Asia Pacific (Sydney)")
	static	public	let	apSoutheast3 = AWSRegion(tag: "ap-southeast-3", name: "Asia Pacific (Jakarta)")
	static	public	let	apSoutheast4 = AWSRegion(tag: "ap-southeast-4", name: "Asia Pacific (Melbourne)")
	static	public	let	apSoutheast5 = AWSRegion(tag: "ap-southeast-5", name: "Asia Pacific (Malaysia)")

	static	public	let	caCentral1 = AWSRegion(tag: "ca-central-1", name: "Canada (Central)")
	static	public	let	caWest1 = AWSRegion(tag: "ca-west-1", name: "Canada West (Calgary)")

	static	public	let	cnNorth1 = AWSRegion(tag: "cn-north-1", name: "China (Beijing)")
	static	public	let	cnNorthwest1 = AWSRegion(tag: "cn-northwest-1", name: "China (Ningxia)")

	static	public	let	euCentral1 = AWSRegion(tag: "eu-central-1", name: "Europe (Frankfurt)")
	static	public	let	euCentral2 = AWSRegion(tag: "eu-central-2", name: "Europe (Zurich)")
	static	public	let	euNorth1 = AWSRegion(tag: "eu-north-1", name: "Europe (Stockholm)")
	static	public	let	euSouth1 = AWSRegion(tag: "eu-south-1", name: "Europe (Milan)")
	static	public	let	euSouth2 = AWSRegion(tag: "eu-south-2", name: "Europe (Spain)")
	static	public	let	euWest1 = AWSRegion(tag: "eu-west-1", name: "Europe (Ireland)")
	static	public	let	euWest2 = AWSRegion(tag: "eu-west-2", name: "Europe (London)")
	static	public	let	euWest3 = AWSRegion(tag: "eu-west-3", name: "Europe (Paris)")

	static	public	let	ilCentral1 = AWSRegion(tag: "il-central-1", name: "Israel (Tel Aviv)")

	static	public	let	meCentral1 = AWSRegion(tag: "me-central-1", name: "Middle East (UAE)")
	static	public	let	meSouth1 = AWSRegion(tag: "me-south-1", name: "Middle East (Bahrain)")

	static	public	let	saEast1 = AWSRegion(tag: "sa-east-1", name: "South America (Sao Paulo)")

	static	public	let	usEast1 = AWSRegion(tag: "us-east-1", name: "US East (N. Virginia)")
	static	public	let	usEast2 = AWSRegion(tag: "us-east-2", name: "US East (Ohio)")
	static	public	let	usGovEast1 = AWSRegion(tag: "us-gov-east-1", name: "AWS GovCloud (US-East)")
	static	public	let	usGovWest1 = AWSRegion(tag: "us-gov-west-1", name: "AWS GovCloud (US-West)")
	static	public	let	usWest1 = AWSRegion(tag: "us-west-1", name: "US West (N. California)")
	static	public	let	usWest2 = AWSRegion(tag: "us-west-2", name: "US West (Oregon)")

	static	public	let	all =
								[
									afSouth1,

									apEast1,
									apNortheast2,
									apNortheast2,
									apNortheast3,
									apSouth1,
									apSouth2,
									apSoutheast1,
									apSoutheast2,
									apSoutheast3,
									apSoutheast4,
									apSoutheast5,

									caCentral1,
									caWest1,

									cnNorth1,
									cnNorthwest1,

									euCentral1,
									euCentral2,
									euNorth1,
									euSouth1,
									euSouth2,
									euWest1,
									euWest2,
									euWest3,

									ilCentral1,

									meCentral1,
									meSouth1,

									saEast1,

									usEast1,
									usEast2,
									usGovEast1,
									usGovWest1,
									usWest1,
									usWest2,
								]
	static	public	let	common =
								[
									usEast1,
									usEast2,
									usWest1,
									usWest2,
								]

			public	let	tag :String
			public	let	name :String

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(tag :String, name :String) {
		// Store
		self.tag = tag
		self.name = name
	}
}

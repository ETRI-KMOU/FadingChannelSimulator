The FadingChannelSimulator function filters an input signal through the multipath fading channel.

This function was developed by Korea Maritime and Ocean University (KMOU), South Korea.

The Seoul and India channel models were co-developed by 
	Electronics and Telecommunications Research Institude (ETRI), South Korea
	Korean Broadcasting System (KBS), South Korea, 
	Universitat Politecnica de Valencia, Spain
	University of the Basque Country, Spain
	Shanghai Jiao Tong University, China
	Mackenzie Presbyterian University, Brazil
	Progira Radio Communication, Sweden
	Sinclair Broadcast Group, USA
	Communications Research Center, Canada

Last Update: 2022.04.01.

===========================
* Syntax
[ChOut, ChannelProfile] = FadingChannelSimulator(in, InputVar)

(1) Output Parameters
ChOut                 : Faded signal output vector (column vector)
ChannelProfile
  |- AvgPathGaindB    : Average path gain in dB
  |- PathDelaySec     ; Path delays [sec]
  |- PathDelaySample  : Path delays [samples]
  |- NumPaths         : number of paths

(2) Input Parameters
in                                : Input signal (column vector)
InputVar
  |- InputVar.ChannelModel       : Channel model ('RL20','RC20','TU-6','TDL-A','TDL-B','TDL-C','TDL-D','TDL-E','Seoul-S1','Seoul-S2','Seoul-S3','India-Rural','India-Urban')
  |- InputVar.SampleRate          : Sample rate [sample/sec]
  |- InputVar.CarrierFrequency   : Carrier frequency [Hz]
  |- InputVar.Speed                : Mobile speed [km/h]
  |- InputVar.Seed                  : Initial seed for channel generation. Random number can be used.
  |- InputVar.DelaySpread         : RMS delay spread for TDL channels in 3GPP. Only used for TDL channel.
===========================

* Note
The first and last portions of the input signal are used for dummy samples corresponding to the amount of the maximum delay spread and channel filter delay.

* References
 See Section Annex B of [1] and TABLE B.1 for 'RL20' and 'RC20' channel models.
 See Section 2.4.4.2 of [2] and TABLE 2.4.2d for 'TU-6' channel model.
 See Section 7.7.2 of [3] and TABLE 7.7.2-1, 7.7.2-2, 7.7.2-3, 7.7.2-4, 7.7.2-5 for 'TDL-A','TDL-B','TDL-C','TDL-D','TDL-E' channel models, respectively.
 See Section III.E of [4] and TABLE VII for 'Seoul-S1' and 'Seoul-S2' channel models.
 See Section III.B of [4] and TABLE V for 'Seoul-S3' channel model.
 See Section IV of [4] and TABLE IX and TABLE VIII for 'India-Rural' and 'India-Urban' channel models, respectively.

[1] Framing Structure, Channel Coding and Modulation for Digital Terrestrial Television, ETSI Standard EN 300 744 V1.6.1, Jan. 2009.
[2] COST 207 Management Committee, COST 207: Digital Land Mobile Radio Communications-Final Report, Commission Eur. Commun., Brussels, Belgium, 1989, pp. 135-147.
[3] 3GPP TR 38.901 V16.1.0, "Study on Channel Model for Frequencies from 0.5 to 100 GHz (Release 16)," Dec. 2019.
[4] Sungjun Ahn, Jeongchang Kim, Seok-Ki Ahn, Sunhyoung Kwon, Sungho Jeon, David Gomez-Barquero, Pablo Angueira, Dazhi He, Cristiano Akamine, Mats Ek, Sesh Simha, Mark Aitken, Zhihong Hunter Hong, Yiyan Wu, and Sung-Ik Park, 
"Characterization and Modeling of UHF Wireless Channel in Terrestrial SFN Environments: Urban Fading Profiles," To be accepted in IEEE Transactions on Broadcasting, 2022.

* Examples
in = 1 - 2*randi([0 1], 1000, 1);
InputVar.ChannelModel     = 'TDL-D';
InputVar.SampleRate        = 6.912*1e6;
InputVar.CarrierFrequency  = 700*1e6;
InputVar.Speed               = 50;
InputVar.Seed                 = 1;
InputVar.DelaySpread       = 2e-6;
[ChOut, ChannelProfile]     = FadingChannelSimulator(in, InputVar);

in = 1 - 2*randi([0 1], 1000, 1);
InputVar.ChannelModel     = 'Seoul-S1';
InputVar.SampleRate        = 6.912*1e6;
InputVar.CarrierFrequency = 700*1e6;
InputVar.Speed              = 50;
InputVar.Seed                = 1;
[ChOut, ChannelProfile]    = FadingChannelSimulator(in, InputVar);

* Requirements
This function uses three system objects from MATLAB Toolbox.

Used system objects:
  comm.RicianChannel (Communications Toolbox)
  comm.RayleighChannel (Communications Toolbox)

Required Toolbox:
  Communications Toolbox

MATLAB version:
  Any version of MATLAB with Communications Toolbox
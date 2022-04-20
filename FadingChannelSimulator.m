function  [ChOut, ChannelProfile] = FadingChannelSimulator(in, InputVar)

% FadingChannelSimulator - Generate faded signal through multipath fading channel
% The FadingChannelSimulator function filters an input signal through the multipath fading channel.
%
% This function was developed by Korea Maritime and Ocean University (KMOU), South Korea.
% 
% The Seoul and India channel models were co-developed by 
% 	Electronics and Telecommunications Research Institude (ETRI), South Korea
% 	Korean Broadcasting System (KBS), South Korea, 
% 	Universitat Politecnica de Valencia, Spain
% 	University of the Basque Country, Spain
% 	Shanghai Jiao Tong University, China
% 	Mackenzie Presbyterian University, Brazil
% 	Progira Radio Communication, Sweden
% 	Sinclair Broadcast Group, USA
% 	Communications Research Center, Canada
%     
% Last Update: 2022.04.05.
% 
% ===========================
% * Syntax
% [ChOut, ChannelProfile] = FadingChannelSimulator(in, InputVar)
%
% (1) Output Parameters
% ChOut                   : Faded signal output vector (column vector)
% ChannelProfile
%   |- AvgPathGaindB      : Average path gain in dB
%   |- PathDelaySec       : Path delays [sec]
%   |- PathDelaySample    : Path delays [samples]
%   |- NumPaths           : number of paths
%   |- PathGains          : Path gains for entire time instances of the channel input vrctor (sample-by-multipath matrix)
%
% (2) Input Parameters
% in                                : Input signal (column vector)
% InputVar
%   |- InputVar.ChannelModel        : Channel model ('RL20','RC20','TU-6','TDL-A','TDL-B','TDL-C','TDL-D','TDL-E','Seoul-S1','Seoul-S2','Seoul-S3','India-Rural','India-Urban')
%   |- InputVar.SampleRate          : Sample rate [sample/sec]
%   |- InputVar.CarrierFrequency    : Carrier frequency [Hz]
%   |- InputVar.Speed               : Mobile speed [km/h]
%   |- InputVar.Seed                : Initial seed for channel generation. Random number can be used.
%   |- InputVar.DelaySpread         : RMS delay spread for TDL channels in 3GPP. Only used for TDL channel.
% ===========================
%
% * Note
% The first and last portions of the input signal are used for dummy samples corresponding to the amount of the maximum delay spread and channel filter delay.
%
% * References
%  See Section Annex B of [1] and TABLE B.1 for 'RL20' and 'RC20' channel models.
%  See Section 2.4.4.2 of [2] and TABLE 2.4.2d for 'TU-6' channel model.
%  See Section 7.7.2 of [3] and TABLE 7.7.2-1, 7.7.2-2, 7.7.2-3, 7.7.2-4, 7.7.2-5 for 'TDL-A','TDL-B','TDL-C','TDL-D','TDL-E' channel models, respectively.
%  See Section III.E of [4] and TABLE VII for 'Seoul-S1' and 'Seoul-S2' channel models.
%  See Section III.B of [4] and TABLE V for 'Seoul-S3' channel model.
%  See Section IV of [4] and TABLE IX and TABLE VIII for 'India-Rural' and 'India-Urban' channel models, respectively.
%
% [1] Framing Structure, Channel Coding and Modulation for Digital Terrestrial Television, ETSI Standard EN 300 744 V1.6.1, Jan. 2009.
% [2] COST 207 Management Committee, COST 207: Digital Land Mobile Radio Communications-Final Report, Commission Eur. Commun., Brussels, Belgium, 1989, pp. 135-147.
% [3] 3GPP TR 38.901 V16.1.0, "Study on Channel Model for Frequencies from 0.5 to 100 GHz (Release 16)," Dec. 2019.
% [4] Sungjun Ahn, Jeongchang Kim, Seok-Ki Ahn, Sunhyoung Kwon, Sungho Jeon, David Gomez-Barquero, Pablo Angueira, Dazhi He, Cristiano Akamine, Mats Ek, Sesh Simha, Mark Aitken, Zhihong Hunter Hong, Yiyan Wu, and Sung-Ik Park,
% "Characterization and Modeling of UHF Wireless Channel in Terrestrial SFN Environments: Urban Fading Profiles," IEEE Transactions on Broadcasting, 2022.
%

ch_model    = InputVar.ChannelModel;
SampleRate  = InputVar.SampleRate;
Fc          = InputVar.CarrierFrequency;
Speed       = InputVar.Speed;
seed        = InputVar.Seed;

T = 1/SampleRate;

NInfdB = -1000;         % negative infinite value [dB]
InfK = 1e10;            % positive infinite value of K factor (for LOS)
fd_zero = 0.001;

c = 299792.458*3600;    % speed of light [km/h]
fd = Speed/c*Fc;      	% maximum Doppler frequency
if fd == 0
    fd_val = fd_zero;
else
    fd_val = fd;
end

% Segmentation of the entire channel output to save the memory usage
SEGMENT_SIZE = 200000;                  % size of one channel segment

switch(ch_model)
    case 'RL20'     % RL20
        AvgPathGain     = [0.057662 0.176809 0.407163 0.303585 0.258782...
                           0.061831 0.150340 0.051534 0.185074 0.400967...
                           0.295723 0.350825 0.262909 0.225894 0.170996...
                           0.149723 0.240140 0.116587 0.221155 0.259730];
        PathDelaySec    = [1.003019 5.422091 0.518650 2.751772 0.602895...
                           1.016585 0.143556 0.153832 3.324866 1.935570...
                           0.429948 3.228872 0.848831 0.073883 0.203952...
                           0.194207 0.924450 1.381320 0.640512 1.368671]*1E-6;
        PathTheta       = [4.855121 3.419109 5.864470 2.215894 3.758058...
                           5.430202 3.952093 1.093586 5.775198 0.154459...
                           5.928383 3.053023 0.628578 2.128544 1.099463...
                           3.462951 3.664773 2.833799 3.334290 0.393889];
        
        AvgPathGaindB   = 10*log10(AvgPathGain.^2);
        NormFactor      = sqrt(sum(AvgPathGain.^2));    % normalization factor
        AvgPathGain     = AvgPathGain/NormFactor;       % normalized average path powers
        
        ChannelFilterDelay = 0;
        % ----------------------------------------------------------------
        
    case 'RC20' % RC20
        AvgPathGain     = [0.057662 0.176809 0.407163 0.303585 0.258782...
                           0.061831 0.150340 0.051534 0.185074 0.400967...
                           0.295723 0.350825 0.262909 0.225894 0.170996...
                           0.149723 0.240140 0.116587 0.221155 0.259730];
        PathDelaySec    = [1.003019 5.422091 0.518650 2.751772 0.602895...
                           1.016585 0.143556 0.153832 3.324866 1.935570...
                           0.429948 3.228872 0.848831 0.073883 0.203952...
                           0.194207 0.924450 1.381320 0.640512 1.368671]*1E-6;
        PathTheta       = [4.855121 3.419109 5.864470 2.215894 3.758058...
                           5.430202 3.952093 1.093586 5.775198 0.154459...
                           5.928383 3.053023 0.628578 2.128544 1.099463...
                           3.462951 3.664773 2.833799 3.334290 0.393889];
        
        % Definition of the direct path
        K               = 10;
        PathLOS         = sqrt(K*sum(AvgPathGain.^2));
        AvgPathGain     = [PathLOS  AvgPathGain];
        PathDelaySec    = [0  PathDelaySec];
        PathTheta       = [0  PathTheta];
        
        AvgPathGaindB   = 10*log10(AvgPathGain.^2);
        NormFactor      = sqrt(sum(AvgPathGain.^2));    % normalization factor
        AvgPathGain     = AvgPathGain/NormFactor;       % normalized average path powers
        
        ChannelFilterDelay = 0;
        % ----------------------------------------------------------------
        
    case 'TU-6' % TU6
        AvgPathGaindB   = [-3.0  0.0  -2.0  -6.0  -8.0  -10.0];         % average path powers [dB]
        PathDelaySec    = [ 0.0  0.2   0.5   1.6   2.3    5.0]*1E-6;    % path delays [sec]
        % ----------------------------------------------------------------
       
    case 'TDL-A'      % TDL-A
        DelaySpread         = InputVar.DelaySpread;
        AvgPathGaindB       = [-13.4  0.0  -2.2  -4.0  -6.0  -8.2  -9.9  -10.5  -7.5  -15.9 ...
                                -6.6  -16.7  -12.4  -15.2  -10.8  -11.3  -12.7  -16.2  -18.3  -18.9 ...
                                -16.6  -19.9  -29.7];         % average path powers [dB]
        PathDelaySec        = [0.0000  0.3819  0.4025  0.5868  0.4610  0.5375  0.6708  0.5750  0.7618  1.5375 ...
                               1.8978  2.2242  2.1718  2.4942  2.5119  3.0582  4.0810  4.4579  4.5695  4.7966 ...
                               5.0066  5.3043  9.6586]*DelaySpread;    % path delays [sec]
        % ----------------------------------------------------------------
        
    case 'TDL-B'      % TDL-B
        DelaySpread         = InputVar.DelaySpread;
        AvgPathGaindB       = [ 0.0  -2.2  -4.0  -3.2  -9.8  -1.2  -3.4  -5.2  -7.6  -3.0 ...
                               -8.9  -9.0  -4.8  -5.7  -7.5  -1.9  -7.6  -12.2  -9.8  -11.4 ...
                               -14.9  -9.2  -11.3];         % average path powers [dB]
        PathDelaySec        = [0.0000  0.1072  0.2155  0.2095  0.2870  0.2986  0.3752  0.5055  0.3681  0.3697 ...
                               0.5700  0.5283  1.1021  1.2756  1.5474  1.7842  2.0169  2.8294  3.0219  3.6187 ...
                               4.1067  4.2790  4.7834]*DelaySpread;    % path delays [sec]
        % ----------------------------------------------------------------
        
    case 'TDL-C'      % TDL-C
        DelaySpread         = InputVar.DelaySpread;
        AvgPathGaindB       = [-4.4  -1.2  -3.5  -5.2  -2.5  0.0  -2.2  -3.9  -7.4  -7.1 ...
                               -10.7  -11.1  -5.1  -6.8  -8.7  -13.2  -13.9  -13.9  -15.8  -17.1 ...
                               -16.0  -15.7  -21.6  -22.8];         % average path powers [dB]
        PathDelaySec        = [0.0000  0.2099  0.2219  0.2329  0.2176  0.6366  0.6448  0.6560  0.6584  0.7935 ...
                               0.8213  0.9336  1.2285  1.3083  2.1704  2.7105  4.2589  4.6003  5.4902  5.6077 ...
                               6.3065  6.6374  7.0427  8.6523]*DelaySpread;    % path delays [sec]
        % ----------------------------------------------------------------
        
    case 'TDL-D'      % TDL-D
        DelaySpread         = InputVar.DelaySpread;
        AvgPathGaindB       = [-0.2  -13.5  -18.8  -21.0  -22.8  -17.9  -20.1  -21.9  -22.9  -27.8  -23.6 ...
                               -24.8  -30.0  -27.7];         % average path powers [dB]
        PathDelaySec        = [0.000  0.000  0.035  0.612  1.363  1.405  1.804  2.596  1.775  4.042  7.937 ...
                               9.424  9.708  12.525]*DelaySpread;    % path delays [sec]
        KFactor             = [InfK 0 0 0 0 0 0 0 0 0 0 ...
                               0 0 0];
        DirectDoppler       = [0.7 0 0 0 0 0 0 0 0 0 0 ...
                                0 0 0]*fd_val;
        DirectPhaseTheta    = zeros(1,14);
        % ----------------------------------------------------------------
        
    case 'TDL-E'      % TDL-E
        DelaySpread         = InputVar.DelaySpread;
        AvgPathGaindB       = [-0.03  -22.03  -15.8  -18.1  -19.8  -22.9  -22.4  -18.6  -20.8  -22.6  -22.3 ...
                                -25.6  -20.2  -29.8  -29.2];         % average path powers [dB]
        PathDelaySec        = [0.0000  0.0000  0.5133  0.5440  0.5630  0.5440  0.7112  1.9092  1.9293  1.9589  2.6426 ...
                                3.7136  5.4524  12.0034  20.6519]*DelaySpread;    % path delays [sec]
        KFactor             = [InfK 0 0 0 0 0 0 0 0 0 0 ...
                                0 0 0 0];
        DirectDoppler       = [0.7 0 0 0 0 0 0 0 0 0 0 ...
                                0 0 0 0]*fd_val;
        DirectPhaseTheta    = zeros(1,15);
        % ----------------------------------------------------------------

    case 'Seoul-S1'     % Seoul-S1 channel
        AvgPathGaindB       = [ -9.46   -7.34   0.00   -1.33   -13.00   -16.54 ];
        PathDelaySec        = [ -14.612268519   -9.403935185   0.000000000   14.033564815   32.407407407   35.300925926 ]*1E-6;
        KFactor             = [0 0 InfK 0 0 0];
        DirectDoppler       = [0 0 0.7 0 0 0]*fd_val;
        DirectPhaseTheta    = zeros(1,6);
        % ----------------------------------------------------------------
                
    case 'Seoul-S2'     % Seoul-S2 channel
        AvgPathGaindB       = [ -6.50   -9.54   0.00   -9.59   -15.84 ];
        PathDelaySec        = [ -49.189814815   -33.564814815   0.000000000   3.327546296   31.684027778 ]*1E-6;
        KFactor             = [InfK 0 InfK 0 0];
        DirectDoppler       = [-1 0 1 0 0]*fd_val;
        DirectPhaseTheta    = zeros(1,5);
        % ----------------------------------------------------------------
                
    case 'Seoul-S3'     % Seoul-S3 channel
        AvgPathGaindB       = [ -0.96   -3.65   0.00   -6.03   -13.74   -0.17 ];
        PathDelaySec        = [ -26.041666667   -12.876157407   0.000000000   10.995370370   13.165509259   37.471064815 ]*1E-6;
        KFactor             = [InfK 0 InfK 0 0 InfK];
        DirectDoppler       = [0.7771 0 -0.3160 0 0 0.4312]*fd_val;
        DirectPhaseTheta    = zeros(1,6);
        % ----------------------------------------------------------------
                
    case 'India-Rural'     % India-Rural channel
        AvgPathGaindB       = [-0.6   0.0   -6.2   -15.3   -28.0   -27.6   -26.6   -28.5   -27.9   -27.2 ...
                              -18.7  -23.1  -27.7  -19.2   -24.5   -22.9   -26.6   -28.0];
        PathDelaySec        = [-6.8   0.0    9.6    21.8    37.7    46.4    52.6    53.8    54.2    59.6 ...
                               60.3   30.7   61.9   62.6    66.6    66.8    67.4    97.9]*1E-6;
        PathTheta           = [2.1388 0.0000 1.6336 5.6888  4.8551  3.7580  3.4191  5.4302  0.1546  2.2159 ...
                               5.8645 3.0530 0.6286 1.0936  3.4630  3.6648  2.8338  3.3343];
        KFactor             = [InfK   InfK   InfK   InfK       0       0       0       0       0       0 ...
                                  0      0      0      0       0       0       0       0];
        DirectDoppler       = [-0.7193 0.9528 0.9371 0.7615    0       0       0       0       0       0 ...
                                0      0      0      0       0       0       0       0]*fd_val;
        DirectPhaseTheta    = zeros(1,18);
        % ----------------------------------------------------------------
                
    case 'India-Urban'     % India-Urban channel
        AvgPathGaindB   = [-1.9   -12.0    0.0   -6.4   -12.5   -21.7   -11.5   -9.7   -22.2   -24.6 ...
                          -17.2   -28.5  -29.1  -29.4   -30.6   -21.7   -27.4  -14.7   -24.9   -19.8];
        PathDelaySec    = [-2.1    -0.8    0.0    0.5     1.3     1.9     4.1    4.6     8.2     9.4 ...
                            9.9    11.9   11.9   12.0    14.8    16.6    18.3   21.2    23.5    26.5]*1E-6;
        % ----------------------------------------------------------------
        
    otherwise, error('Wrong channel model !!!')
end

% ------------------------------------------------------------------------


% Channel object generation
if(strcmp(ch_model,'TU-6') || strcmp(ch_model,'TDL-A') || strcmp(ch_model,'TDL-B') || strcmp(ch_model,'TDL-C') || strcmp(ch_model,'India-Urban'))
    % NLoS channel
    Chan = comm.RayleighChannel('SampleRate',SampleRate, ...
                                'PathDelays',PathDelaySec, ...
                                'AveragePathGains',AvgPathGaindB, ...
                                'NormalizePathGains',1, ...
                                'MaximumDopplerShift',fd_val, ...
                                'FadingTechnique','Sum of sinusoids', ...
                                'NumSinusoids',8, ...
                                'RandomStream','mt19937ar with seed', ...
                                'Seed',seed, ...
                                'PathGainsOutputPort',true, ...
                                'Visualization','off');
    ChanInfo = info(Chan);
    ChannelFilterDelay          = ChanInfo.ChannelFilterDelay;
    
elseif(strcmp(ch_model,'TDL-D') || strcmp(ch_model,'TDL-E') || strcmp(ch_model,'Seoul-S1') || strcmp(ch_model,'Seoul-S2') || strcmp(ch_model,'Seoul-S3') || strcmp(ch_model,'India-Rural'))
    % LoS channel
    Chan = comm.RicianChannel(  'SampleRate',SampleRate, ...
                                'PathDelays',PathDelaySec, ...
                                'AveragePathGains',AvgPathGaindB, ...
                                'NormalizePathGains',1, ...
                                'KFactor',KFactor, ...
                                'DirectPathDopplerShift',DirectDoppler, ...
                                'DirectPathInitialPhase',DirectPhaseTheta, ...
                                'MaximumDopplerShift',fd_val, ...
                                'FadingTechnique','Sum of sinusoids', ...
                                'NumSinusoids',8, ...
                                'RandomStream','mt19937ar with seed', ...
                                'Seed',seed, ...
                                'PathGainsOutputPort',true, ...
                                'Visualization','OFF');
    ChanInfo = info(Chan);
    ChannelFilterDelay          = ChanInfo.ChannelFilterDelay;

end

PathDelaySample = round(PathDelaySec/T);	% path delays [sample]
MaxDelaySample  = max(PathDelaySample);     % maximum delay spread
NumPaths        = length(PathDelaySec);     % # of paths

% Channel filter input
filter_in   = [in(end - MaxDelaySample + 1 : end, 1) ; ...        % dummy
               in ; ...
               in(1 : MaxDelaySample + ChannelFilterDelay, 1)];   % dummy

Ns          = length(filter_in(:,1));
fadedSig	= zeros(Ns, 1);
PathGains	= zeros(Ns, NumPaths);

% channel output
% The first and last portions of the input signal are used for dummy samples corresponding to the amount of the maximum delay spread and channel filter delay.
if(strcmp(ch_model,'RL20') || strcmp(ch_model,'RC20'))
    for path = 1 : NumPaths
        fadedSig(PathDelaySample(path)+1:end) = fadedSig(PathDelaySample(path)+1:end) ...
            + AvgPathGain(path)*exp(-1j*PathTheta(path)) * filter_in(1:end-PathDelaySample(path));
    end
else
    % Segmentation of the entire channel output to save the memory usage
    SEGMENT_NUM = ceil(Ns/SEGMENT_SIZE);	% # of channel segments

    for seg_idx = 1 : SEGMENT_NUM-1
        [fadedSig(SEGMENT_SIZE*(seg_idx-1)+1:SEGMENT_SIZE*seg_idx,1),PathGains(SEGMENT_SIZE*(seg_idx-1)+1:SEGMENT_SIZE*seg_idx,:)] ...
            = Chan(filter_in(SEGMENT_SIZE*(seg_idx-1)+1:SEGMENT_SIZE*seg_idx,1));
    end
    seg_idx = SEGMENT_NUM;
    [fadedSig(SEGMENT_SIZE*(seg_idx-1)+1:end,1),PathGains(SEGMENT_SIZE*(seg_idx-1)+1:end,:)] ...
        = Chan(filter_in(SEGMENT_SIZE*(seg_idx-1)+1:end,1));
end
% ignore the channel output before the last multipath signal is input into the channel
ChOut = fadedSig(ChannelFilterDelay + MaxDelaySample + 1 : end - MaxDelaySample);
% ------------------------------------------------------------------------

ChannelProfile.AvgPathGaindB        = AvgPathGaindB;
ChannelProfile.PathDelaySec         = PathDelaySec;
ChannelProfile.PathDelaySample      = PathDelaySample;
ChannelProfile.NumPaths             = NumPaths;
ChannelProfile.PathGains            = PathGains;

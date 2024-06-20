clear all
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%
max_range = 200;

%speed of light = 3e8
c = 3e8;
%% User Defined Range and Velocity of target
% *%DONE* :
% define the target's initial position and velocity. Note : Velocity
% remains contant
R = 150; % initial range of the target in meters
v = -50; % velocity of the target in m/s (negative indicates moving towards the radar)


%% FMCW Waveform Generation

% *%DONE* :
%Design the FMCW waveform by giving the specs of each of its parameters.
% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.
range_resolution = 1; % meter
B = c / (2 * range_resolution); % Bandwidth for the given range resolution
Tchirp = 5.5 * (2 * max_range / c); % Chirp time for the given maximum range
slope = B / Tchirp; % slope of FMCW chirp

disp(['slope: ', num2str(B)]);


%Operating carrier frequency of Radar 
fc= 77e9;             %carrier freq

                                                          
%The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT
%for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx=zeros(1,length(t)); %transmitted signal
Rx=zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));


%% Signal generation and Moving Target simulation
% Running the radar scenario over the time. 

for i=1:length(t)         
    % *%DONE* :
    %For each time stamp update the Range of the Target for constant velocity. 
    r_t(i) = R + v * t(i);
    td(i) = 2 * r_t(i) / c;
    
    % *%DONE* :
    %For each time sample we need update the transmitted and
    %received signal. 
    Tx(i) = cos(2 * pi * (fc * t(i) + (slope * t(i)^2) / 2));
    Rx(i) = cos(2 * pi * (fc * (t(i) - td(i)) + (slope * (t(i) - td(i))^2) / 2));
    
    % *%DONE* :
    %Now by mixing the Transmit and Receive generate the beat signal
    %This is done by element wise matrix multiplication of Transmit and
    %Receiver Signal
    Mix(i) = Tx(i) .* Rx(i);
    
end

%% RANGE MEASUREMENT


 % *%DONE* :
%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.
Mix = reshape(Mix, [Nr, Nd]);

 % *%DONE* :
%run the FFT on the beat signal along the range bins dimension (Nr) and
%normalize.
sig_fft = fft(Mix, [], 1)./Nr; % FFT along the range bins

 % *%DONE* :
% Take the absolute value of FFT output
sig_fft = abs(sig_fft);

% Find the largest value for each row
sig_fft = max(sig_fft, [], 2);

 % *%DONE* :
% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
sig_fft = sig_fft(1:Nr/2);


%plotting the range
figure('Name', 'Range from First FFT')
title('Range from First FFT')
subplot(2,1,1)

 % *%DONE* :
 % plot FFT output 
plot(sig_fft(:, 1)); % plot the first column of FFT results
axis ([0 200 0 1]);


%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map. You will implement CFAR on the generated RDM

% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix = reshape(Mix, [Nr, Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix, Nr, Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2, 1:Nd);
sig_fft2 = fftshift(sig_fft2);
RDM = abs(sig_fft2);
RDM = 10 * log10(RDM);

% Use the surf function to plot the output of 2DFFT and to show axis in both dimensions
doppler_axis = linspace(-100, 100, Nd);
range_axis = linspace(-200, 200, Nr/2) * ((Nr/2) / 400);
figure, surf(doppler_axis, range_axis, RDM);
title('Range-Doppler Map from 2D FFT')
ylabel('Range (m)')
xlabel('Velocity (m/s)')
zlabel('dB')

%% CFAR implementation

% Slide Window through the complete Range Doppler Map

% *%DONE* : Select the number of Training Cells in both the dimensions.
Tr = 8;  % Training cells in range dimension
Td = 8;   % Training cells in doppler dimension

% *%DONE* : Select the number of Guard Cells in both dimensions around the Cell under test (CUT) for accurate estimation
Gr = 4;   % Guard cells in range dimension
Gd = 4;   % Guard cells in doppler dimension

% *%DONE* : offset the threshold by SNR value in dB
offset = 6;  % SNR offset in dB

% *%DONE* : Create a vector to store noise_level for each iteration on training cells
cfar_map = zeros(Nr/2, Nd); % Only half of symmetry considered

totalCells = (2 * (Tr + Gr) + 1) * (2 * (Td + Gd) + 1);
guardCells = (2 * Gr + 1) * (2 * Gd + 1);
trainingCells = totalCells - guardCells;

% *%DONE* :
%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.

% Use RDM[x,y] as the matrix from the output of 2D FFT for implementing
% CFAR

% Precompute power values of the RDM
powerRDM = db2pow(RDM);

% Range
for i = (Tr + Gr + 1) : (Nr/2 - Tr - Gr) 

   % Doppler
   for j = (Td + Gd + 1) : (Nd - Td - Gd)

        % Extract the patch for processing
        patch = powerRDM((i - Tr - Gr) : (i + Tr + Gr), (j - Td - Gd) : (j + Td + Gd));

        % Mask for guard cells and the Cell Under Test (CUT)
        mask = ones(size(patch));
        mask((Tr + 1) : (end - Tr), (Td + 1) : (end - Td)) = 0;
        
        % Calculate the training cell noise level
        noiseLevelSum = sum(patch(mask == 1));
        avgNoiseLevel = noiseLevelSum / trainingCells;
        noiseThreshold = pow2db(avgNoiseLevel * offset);

        % CFAR detection logic
        if RDM(i, j) > noiseThreshold
            cfar_map(i, j) = 1;
        end
   end
end

% *%DONE* :
% The process above will generate a thresholded block, which is smaller 
% than the Range Doppler Map as the CUT cannot be located at the edges of
% matrix. Hence, few cells will not be thresholded. To keep the map size same
% set those values to 0.

cfar_map(1:(Tr+Gr), :) = 0;
cfar_map((end-Tr-Gr+1):end, :) = 0;
cfar_map(:, 1:(Td+Gd)) = 0;
cfar_map(:, (end-Td-Gd+1):end) = 0;

% Display the CFAR output using the Surf function like we did for Range Doppler Response output.
figure, surf(doppler_axis, range_axis, cfar_map);
colorbar;
title('2D CFAR Range Doppler Map');
title("2D CFAR on Range-Doppler Map")
xlabel('Velocity (m/s)')
ylabel('Range (m)')
zlabel('CFAR Detection')
 
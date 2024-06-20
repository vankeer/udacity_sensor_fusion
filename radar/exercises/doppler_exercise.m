% Doppler Velocity Calculation
c = 3*10^8;         %speed of light
frequency = 77e9;   %frequency in Hz

% Calculate the wavelength
lambda = c / frequency;

% Define the Doppler shifts in Hz (example values)
doppler_shifts = [3000, -4500, 11000, -3000];  % Doppler shifts in Hz

% Calculate the velocity of the targets fd = 2*vr/lambda
% vr = fd * lambda / 2
velocities = doppler_shifts * lambda / 2;

% Display results
disp('Doppler Shifts (Hz):');
disp(doppler_shifts);
disp('Velocities of targets (m/s):');
disp(velocities);
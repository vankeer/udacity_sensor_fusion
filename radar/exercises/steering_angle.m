% Constants
frequency = 77e9;  % Frequency of operation in Hz
c = 3e8;  % Speed of light in m/s
phase_increment_deg = 45;  % Phase increment in degrees

% Convert phase increment to radians
phase_increment_rad = phase_increment_deg * pi / 180;

% Calculate the wavelength
wavelength = c / frequency;

% Antenna element spacing (half-wavelength)
d = wavelength / 2;

% Calculate steering angle in radians
steering_angle_rad = asin((phase_increment_rad * wavelength) / (2 * pi * d));

% Convert steering angle to degrees
steering_angle_deg = steering_angle_rad * 180 / pi;

% Display the result
disp(['The steering angle of the antenna beam is ', num2str(steering_angle_deg), ' degrees.']);

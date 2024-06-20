% Radar data matrix size (example)
N_range = 128;  % Number of range cells
N_doppler = 128;  % Number of Doppler cells

% Generate a random noise floor with a few random targets added
noise_floor = abs(randn(N_range, N_doppler));
targets = [50, 60; 80, 90; 120, 30];  % Example target positions
for idx = 1:size(targets, 1)
    noise_floor(targets(idx, 1), targets(idx, 2)) += rand()*40 + 10;  % Adding target signals
end

% Define CFAR parameters
Tr = 8;  % Training cells in range dimension
Gr = 4;  % Guard cells in range dimension
Td = 4;  % Training cells in Doppler dimension
Gd = 2;  % Guard cells in Doppler dimension

% Calculate number of training cells
total_training_cells = ((2*Tr + 2*Gr + 1) * (2*Td + 2*Gd + 1)) - ((2*Gr + 1) * (2*Gd + 1));

% CFAR output matrix initialization
CFAR_out = zeros(N_range, N_doppler);

% Slide window across the entire matrix
for i = 1 + (Tr + Gr) : N_range - (Tr + Gr)
    for j = 1 + (Td + Gd) : N_doppler - (Td + Gd)
        % Extract the patch around the CUT
        patch = noise_floor(i - Tr - Gr : i + Tr + Gr, j - Td - Gd : j + Td + Gd);
        
        % Set the guard cells and CUT to zero
        patch(Tr + 1 : end - Tr, Td + 1 : end - Td) = 0;
        
        % Calculate the average noise (threshold) in the training cells
        noise_level = mean(patch(:));
        
        % Define the offset for thresholding (example offset)
        offset = 5;
        
        % Calculate the threshold
        threshold = noise_level + offset;
        
        % Determine if the CUT is above the threshold
        if noise_floor(i, j) > threshold
            CFAR_out(i, j) = 1;
        else
            CFAR_out(i, j) = 0;
        end
    end
end

% Suppress the edges
CFAR_out(1:Tr+Gr, :) = 0;
CFAR_out(end-Tr-Gr+1:end, :) = 0;
CFAR_out(:, 1:Td+Gd) = 0;
CFAR_out(:, end-Td-Gd+1:end) = 0;

% Display the result
imagesc(CFAR_out);
colormap('gray');
title('2D CFAR Detection');
xlabel('Doppler Dimension');
ylabel('Range Dimension');

% Output the total number of training cells
disp(['Total number of training cells: ', num2str(total_training_cells)]);

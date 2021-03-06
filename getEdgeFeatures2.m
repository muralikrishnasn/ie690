function [movie_features, EdgeX, EdgeY] = getEdgeFeatures2(K0)


    K = K0;
    NUM_DEPTH_THRESHOLD = 10;
    NUM_NOISE_THRESHOLD = 0.05;

%% ================== Find Edge Features ====================================

    %thresholds should be dependent on histogram 
   

    % preallocate
    EdgeX = [];
    EdgeY = [];
    
    movie_features = [];
    
    
    for i = 1:length(K)

             
        
        %Deok's Code for edge features
        I = K(i).cdata(:, :, 1);
        
        %figure, subplot(1,2,1), image(I), colormap(jet(256));
        
        I = removeNoise(I);
        I = removeNoise(I);

        I2 = I/NUM_DEPTH_THRESHOLD;
        I3 = I2*NUM_DEPTH_THRESHOLD;

        % figure, imshow(I3), colormap('jet');
        % 
        % figure, imhist(I);

        I4 = double(I/256);
        [BW thresh] = edge(I4, 'canny',[0.1, 0.3]);

        % figure, imshow(BW), title('canny');
        % 
        % [BW thresh] = edge(I4, 'sobel');
        % 
        % figure, imshow(BW),title('sobel');
        % 
        % [BW thresh] = edge(I4, 'prewitt');
        % 
        % figure, imshow(BW),title('prewitt');
        % 
        % 
        % 
        % [BW thresh] = edge(I4, 'log');
        % 
        % figure, imshow(BW),title('log');
        % 


        level = graythresh(I4);
        I4( find(I4 > level) ) = 1; 
        BW2 = im2bw(I4, level);
        [L num] = bwlabel (~BW2,8);
        for j=1:num
            if  length( find(L == j) ) < 100 
                BW2( find(L ==j) ) = 1;
            end
        end

        SE = strel('disk',3,0);
        BW3 = imdilate(~BW2,SE);

        BW4 = BW & BW3; 

        % figure, imshow( BW4);


        [L num] = bwlabel (BW4,8);

        for j=1:num

            if  length( find(L == j) ) < 10 

                BW4( find(L == j) ) = 0;
            end
        end
        
        %subplot(1,2,2), image( BW4*255), title(num2str(i));

        
        [Px, Py] = find(BW4);
        
        % Karthik's code: get Edge features
        %[Px, Py] = find(((Gx.^2 + Gy.^2).^(0.5)> THRESHOLD_FEATURE));

        
        EdgeX = [EdgeX; Px];
        EdgeY = [EdgeY; Py];
        
        result = [Px Py];
        
        
        movie_features = [movie_features, struct('frame', result)];
        
        %show edge image
        %figure 
        %imshow((Gx.^2 + Gy.^2).^(0.5)> THRESHOLD_FEATURE);
        
        
end


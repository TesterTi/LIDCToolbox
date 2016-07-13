function [gts, slice_index, imageInfo, z_pos] = LIDC_pmap_2_mat(data_dir, filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% LIDC Toolbox
%
% If you use the software for research purposes I kindly ask you to cite
% the following paper:
%
%    T. Lampert, A. Stumpf, and P. Gancarski, 'An Empirical Study of Expert 
%       Agreement and Ground Truth Estimation', IEEE Transactions on Image
%       Processing 25 (6): 2557–2572, 2016.
%
%
% Used by LIDC_pmap_2_mat to convert the XML probability map calculated 
% from the LIDC annotations into an image and save it as a MAT file.
%
%
%   Thomas Lampert, http://sites.google.com/site/tomalampert
%  
%   Copyright 2013
%
%
%   This is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This software is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this software. If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




try
    docNode = xmlread([data_dir filename]);
catch e
    warning('Invalid or empty XML file (happens if reader only annotated small nodes, <= 3mm), ignoring...');
    gts = [];
    return
end

fprintf('Converting PMAP to MAT format...');

document = docNode.getDocumentElement;
reading_sessions = document.getChildNodes;



slice_index = [];
z_pos = [];
c1 = 0;
c_gt = 1;
while ~isempty(reading_sessions.item(c1))
    
    if strcmpi(reading_sessions.item(c1).getNodeName, 'DataInfoHeader')
        % Get image size information
        
        data_info = reading_sessions.item(c1).getChildNodes;
        
        c2 = 0;
        
        while ~isempty(data_info.item(c2))
            
            if strcmpi(data_info.item(c2).getNodeName, 'ImageGeometry')
                x_size = str2double(char(data_info.item(c2).getAttributes.getNamedItem('xdim').getTextContent));
                y_size = str2double(char(data_info.item(c2).getAttributes.getNamedItem('ydim').getTextContent));
            end
        
            c2 = c2+1;
            
        end
        
        gts = zeros(y_size, x_size, 1);
        
    end
    
    if strcmpi(reading_sessions.item(c1).getNodeName, 'Pmaps')
        
        current_reading_session = reading_sessions.item(c1).getChildNodes;
        
        cx = 0;
        while ~isempty(current_reading_session.item(cx))

            if strcmpi(current_reading_session.item(cx).getNodeName, 'PmapData')
                
                current_pmap_data = current_reading_session.item(cx).getChildNodes;

                c2 = 0;
                while ~isempty(current_pmap_data.item(c2))

                    if strcmpi(current_pmap_data.item(c2).getNodeName, 'Slice')

                        slice_index{c_gt} = char(current_pmap_data.item(c2).getAttributes.getNamedItem('sopinstanceuid').getTextContent);

                        z_pos(c_gt) = str2double(char(current_pmap_data.item(c2).getAttributes.getNamedItem('z').getTextContent));

                        current_roi = current_pmap_data.item(c2).getChildNodes;

                        x = [];
                        y = [];
                        count = [];
                        c3 = 0;
                        while ~isempty(current_roi.item(c3))

                            if strcmpi(current_roi.item(c3).getNodeName, 'Count')
                                count = [count str2num(current_roi.item(c3).getTextContent)];

                                x = [x str2num(current_roi.item(c3).getAttributes.getNamedItem('i').getTextContent)];
                                y = [y str2num(current_roi.item(c3).getAttributes.getNamedItem('j').getTextContent)];
                            end
                            c3 = c3+1;
                        end

                        for i = 1:numel(x)
                            gts(y(i), x(i), c_gt) = count(i);
                        end

                        c_gt = c_gt + 1;
                    end

                    c2 = c2+1;

                end
            
            end
            
            cx = cx + 1;
            
        end
        
    end
    
    c1 = c1+1;

end

%[slice_index, s_ind] = sort(slice_index);
%gts = gts(:,:,s_ind);

[data_dir filename(1:end-4)]

save([data_dir filename(1:end-4)], 'gts', 'slice_index', 'z_pos');

end



function imageInfo = getImageGeometry(appInfoHeaderNode)

    contentNodes = appInfoHeaderNode.getChildNodes;
    
    c1 = 0;
    while ~isempty(contentNodes.item(c1))
        
        if strcmpi(contentNodes.item(c1).getNodeName, 'ImageGeometry')
            
            imageInfo.pixelSize = str2num(contentNodes.item(c1).getAttributes.getNamedItem('pixelsize').getTextContent);
            imageInfo.XDim = str2num(contentNodes.item(c1).getAttributes.getNamedItem('xdim').getTextContent);
            imageInfo.YDim = str2num(contentNodes.item(c1).getAttributes.getNamedItem('ydim').getTextContent);
            imageInfo.SliceSpacing = str2num(contentNodes.item(c1).getAttributes.getNamedItem('slicespacing').getTextContent);
            
        end
        
        c1 = c1 + 1;
    end

end
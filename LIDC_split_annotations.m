function [new_xml_paths, new_xml_filenames, studyID] = LIDC_split_annotations(xml_path, filename)


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
% The annotations from each annotator within the LIDC database are 
% contained within the same XML file. This function splits the annotations
% for each expert into different XML files allowing the GTs to be
% reconstructed using LIDC_xml_2_pmap. (If they were all in the same file 
% then LIDC_xml_2_pmap creates probability maps in which the individual 
% markings cannot be discerned.)
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


xml_path = correct_path(xml_path);

try
    docNode = xmlread([xml_path filesep filename]);
catch e
    error('Failed to read XML file %s.', filename);
end



document = docNode.getDocumentElement;
reading_sessions = document.getChildNodes;


% Count the number of readers in the XML file
c1 = 0;
reading_session_count = 0;
while ~isempty(reading_sessions.item(c1))
    
    if strcmpi(reading_sessions.item(c1).getNodeName, 'ResponseHeader')
        
        studyID = getStudyInstanceUID(reading_sessions.item(c1));
        
    end
    
    if strcmpi(reading_sessions.item(c1).getNodeName, 'readingSession')
        
        reading_session{reading_session_count+1} = reading_sessions.item(c1);
        
        reading_session_count = reading_session_count + 1;
        
    end
    c1 = c1 + 1;
end


% Split the readers annotations into separate files
new_xml_paths     = cell(1, reading_session_count);
new_xml_filenames = cell(1, reading_session_count);
for i = 1:reading_session_count

    
    % Create a new folder for each annotation
    new_xml_paths{i}     = [xml_path num2str(i) filesep];
    [~, fname] = fileparts(filename);
    new_xml_filenames{i} = [fname '_' num2str(i) '.xmltemp'];
    if ~exist(new_xml_paths{i}, 'dir')
        mkdir(new_xml_paths{i})
    end
    
    
    new_docNode          = docNode.cloneNode(1);
    new_document         = new_docNode.getDocumentElement;
    new_reading_sessions = new_document.getChildNodes;

    new_reading_count = 1;
    c1 = 0;
    while ~isempty(new_reading_sessions.item(c1))
        
        if strcmpi(new_reading_sessions.item(c1).getNodeName, 'readingSession')
            
            if i ~= new_reading_count
                new_reading_sessions.removeChild(new_reading_sessions.item(c1));
            end
            
            new_reading_count = new_reading_count + 1;
            
        end
        
        c1 = c1 + 1;
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The reason for the following code is that MAX requires that there be 
    % more than one reader in each XML file, we have just removed all the 
    % others as we want to extract the individual readers. So now we add a 
    % dummy empty reader entry. XML Code:
    %
    % <readingSession>
    %     <annotationVersion>3.12</annotationVersion>
    %     <servicingRadiologistID>anon</servicingRadiologistID>
    % </readingSession>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    entry_node = new_docNode.createElement('readingSession');
    new_docNode.getDocumentElement.appendChild(entry_node);
    
    name_node = new_docNode.createElement('annotationVersion');  
    name_text = new_docNode.createTextNode('3.12');
    name_node.appendChild(name_text);
    entry_node.appendChild(name_node);
    
    phone_number_node = new_docNode.createElement('servicingRadiologistID');
    phone_number_text = new_docNode.createTextNode('anon');
    phone_number_node.appendChild(phone_number_text);
    entry_node.appendChild(phone_number_node);
    
    
    % Output the individual's annotation
    
    xmlwrite([new_xml_paths{i} new_xml_filenames{i}], new_docNode);
    
    clear new_docNode new_document new_reading_sessions
end

end

function studyID = getStudyInstanceUID(responseHeaderNode)

    contentNodes = responseHeaderNode.getChildNodes;
    
    c1 = 0;
    while ~isempty(contentNodes.item(c1))
        
        if strcmpi(contentNodes.item(c1).getNodeName, 'StudyInstanceUID')
            
            studyID = char(contentNodes.item(c1).getTextContent);
            
            studyID = strrep(studyID, '1.3.6.1.4.1.14519.5.2.1.6279.6001.', '');
            
        end
        
        c1 = c1 + 1;
    end

end
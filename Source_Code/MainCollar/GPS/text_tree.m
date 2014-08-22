function string_tree = text_tree (strings)
%TEXT_TREE    Convert a vector of text strings into a tree of char nodes.
% usage string_tree = text_tree (strings)
%       string_tree = vector of character match nodes that make up the tree.
%           strings = cell array of strings.
%
%   example:
%     strings = {'string 1' 'string 2' ...}
%

% --------------------------------------------------------------------------
%
%%  @file       text_tree.m
%   @brief      Converts a vector of text strings into a tree of char nodes.
%   @details    Each node contains a character and a pointer to a list of
%               nodes for characters that can follow it in one of the
%               input strings.
%   @author     Emery Newlon
%   @date       August 2014
%   @copyright  Copyright (C) 2014 Ross K. Snider and Emery L. Newlon

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%   Emery Newlon
%   Electrical and Computer Engineering
%   Montana State University
%   610 Cobleigh Hall
%   Bozeman, MT 59717
%   emery.newlon@msu.montana.edu
%
% --------------------------------------------------------------------------


%   A character that will never show up in any string.

not_char        = char (127) ;

%   Encoding shift multipliers.

enc_list_char   = uint32 (2 ^ 0)  ;
enc_list_end    = uint32 (2 ^ 8) ;
enc_list_number = uint32 (2 ^ 9) ;
enc_list_offset = uint32 (2 ^ (fix (log2 (length (strings))) + 1 + 9)) ;

%   Convert the vector into a series of rows with row numbers in a separate
%   column.

string_tbl      = [strings(:)' ; num2cell([0:length(strings)-1])]' ;

%   Sort the table by string value and determine the dimensions of the
%   result.

sorted_tbl      = sortrows (string_tbl) ;

sorted_strs     = sorted_tbl (:,1) ;

tot_strs        = uint32 (length (sorted_strs)) ;
tot_chars       = uint32 (length ([sorted_strs{:}])) ;

string_numbers  = cell (tot_strs, 2) ;

%   Tree nodes before encoding.

max_space       = uint32 (tot_strs + tot_chars + 1) ;

chars           = zeros (1, max_space) ;
offsets         = zeros (1, max_space, 'uint32') ;
listend         = zeros (1, max_space, 'uint32') ;
stringnos       = zeros (1, max_space, 'uint32') ;

%   Stack for string processing.

stack           = zeros (1, max_space) ;

%   Start the tree with a list terminated empty node.

chars     (1)   = not_char ;
offsets   (1)   = uint32 (0) ;
listend   (1)   = uint32 (1) ;
stringnos (1)   = tot_strs ;
next_node       = uint32 (2) ;

%   Add the first letter of each string to the tree.

last_ch                   = not_char ;

for k = 1 : length (sorted_strs)
  str                     = [sorted_strs{k}] ;

  if (str (1) ~= last_ch)
    last_ch               = str (1) ;

    chars     (next_node) = last_ch ;
    offsets   (next_node) = uint32 (0) ;
    listend   (next_node) = uint32 (0) ;
    stringnos (next_node) = tot_strs ;

    next_node             = uint32 (next_node + 1) ;
  end

  %   Add the string numbers of the strings to the result table.

  string_numbers {k, 1} = uint32 (sorted_tbl {k, 2}) ;
  string_numbers {k, 2} = uint32 (next_node - 1) ;
end

%   Mark the end of the initial list.

listend (next_node - 1) = uint32 (1) ;

%   Push the index of the first character in the list onto the stack.

tos                 = uint32 (1) ;
stack (tos)         = uint32 (1) ;

%   Process all the rest of the characters in the strings.

prefix              = [not_char] ;

while (tos > 0)

  %   Take the last list entry offset from the top-of-stack and advance to
  %   the next node.

  stack (tos)       = uint32 (stack (tos) + 1) ;
  cur_node          = stack (tos) ;

  %   Add the list's current character to the prefix string.

  preflen           = uint32 (length (prefix)) ;
  prefix (preflen)  = chars (cur_node) ;
  lastch            = not_char ;

  %   Save the start of the new list (if there is one).

  list_start        = next_node ;

  %   Add the characters to the tree for strings that match the current
  %   prefix.

  for k = 1 : length (sorted_strs)
    str             = [sorted_strs{k}] ;

    if (length (str) > preflen)
      if (min (str (1:preflen) == prefix))

        %   The offset for this character's list of following characters
        %   will be updated each time a character is added to the current
        %   list.

        offsets (cur_node)      = uint32 (list_start - cur_node) ;

        %   When a new character is found for this character's list add it
        %   to the new list.

        if (str (preflen + 1) ~= last_ch)
          last_ch               = str (preflen + 1) ;

          chars     (next_node) = last_ch ;
          offsets   (next_node) = uint32 (0) ;
          listend   (next_node) = uint32 (0) ;
          stringnos (next_node) = tot_strs ;

          next_node             = uint32 (next_node + 1) ;
        end

        %   Update the string's number with the new last character in the
        %   current character's list.

        string_numbers {k, 2}   = uint32 (next_node - 1) ;
      end
    end
  end

  %   If a new list was started mark its last node as the end of that list.
  %   Push the start of the new list onto the stack.

  if (list_start < next_node)
    listend (next_node - 1)   = uint32 (1) ;

    tos                       = uint32 (tos + 1) ;
    stack (tos)               = list_start ;

    prefix                    = [prefix not_char] ;

  %   If the last node processed was the end of the current list we're done
  %   with it.  Return to the previous list level by popping this list off
  %   the stack.

  else
    while (tos > 0 && listend (cur_node) == 1)
      tos                     = uint32 (tos - 1) ;

      if (tos > 0)
        cur_node              = stack (tos) ;

        prefix                = prefix (1 : preflen - 1) ;
      end
    end
  end
end

%   Update the nodes with the numbers of the strings that they are the last
%   character in.

for k = 1 : tot_strs
  stringnos (string_numbers {k, 2}) = string_numbers {k, 1} ;
end

%   Encode all the tree node data into a single number per node.

string_tree = zeros (1, next_node - 1, 'uint32') ;

for k = 1 : next_node - 1

  string_tree (k)     = uint32 (chars     (k) * enc_list_char   +   ...
                                offsets   (k) * enc_list_offset +   ...
                                stringnos (k) * enc_list_number +   ...
                                listend   (k) * enc_list_end) ;

end

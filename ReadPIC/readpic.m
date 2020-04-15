function ImageSequenceOfCurrentFile =           readpic(filename)
% read in a Biorad .pic image file
% image = readpic(filename)

% adapted from:
% http://www.bu.edu/cism/cismdx/ref/dx.Samples/util/biorad-pic/PIC2dx.c
% http://rsb.info.nih.gov/ij/plugins/download/Biorad_Reader.java
        
MetaData =                                      impicinfo(filename);

ImageWidth=                                     MetaData.Width;
ImageHeight=                                    MetaData.Height;
NumberOfReads=                                  MetaData.NumImages;
BithDepth=                                      ['uint' sprintf('%0.0f', MetaData.BitDepth)];

fid =                                           fopen(filename, 'r');

% skip over the header
fseek(fid, 76, 'bof');

% read data: one image is located just after each other;
ImageSequenceOfCurrentFile =                zeros(ImageWidth, ImageHeight, NumberOfReads);        
for x = 1:NumberOfReads

    CurrentImage=                           fliplr(fread(fid, [ImageWidth, ImageHeight], BithDepth));
    ImageSequenceOfCurrentFile(:,:,x) =     CurrentImage;


end
    
fclose(fid);
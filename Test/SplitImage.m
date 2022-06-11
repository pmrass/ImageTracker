function SplitImage(lib)
%SPLITIMAGE Summary of this function goes here
%   Detailed explanation goes here

movie = lib.getActiveMovieController.getLoadedMovie;

Image = movie.getActiveImage;

a = Image(2600:2900, 2600:2900);

figure(999)
imagesc(a)


h = strel('disk', 7);
a = imdilate(a, h);
figure(1000)
imagesc(a)

figure(1001)
D = bwdist(-a);
imagesc(D)

figure(1002)
L = watershed(-D);



end

function edge(obj)


figure(1001)
eges = edge(a, 'Canny', [0.15, 0.3]);
h = strel('disk', 2);



eges = imdilate(eges, h);
eges = imdilate(eges, h);

imagesc(eges)

figure(1002)
%eges = edge(a);

eges = bwmorph(eges, 'skel');

imagesc(eges)

figure(1003)
%eges = edge(a);

eges = bwmorph(eges, 'skel');

imagesc(eges)

figure(1004)
%eges = edge(a);

eges = bwmorph(eges, 'skel');

imagesc(eges)



end



function drawCircle(xc,yc,r,c,lw)
    theta=0:0.001:2*pi; 
    hold on
    for i = 1:size(r,1)
        x=r(i).*cos(theta);
        y=r(i).*sin(theta);
        plot(xc+x,yc+y,c(i,:),'linewidth',lw);
    end
    hold off
end

Te = 1E7;
t = 0:1/Te:2;

x = [zeros(1,Te/2) 2*t(1:Te/2) 1 fliplr(2*t(1:Te/2)) zeros(1,Te/2)];

plot(t, x)
xlabel('\frac{\tau}{T_s}')
ylabel('Amplitude normalisée')
xlim([-0.05 2.05])
ylim([-0.05 1.05])
grid on
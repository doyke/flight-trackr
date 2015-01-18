Te = 1E7;
t = 0:1/Te:1-1/Te;
p0 = [zeros(1,Te/2) ones(1,Te/2)];
p1 = [ones(1,Te/2) zeros(1,Te/2)];

subplot(1,2,1)
plot(t, p0)
xlabel('Temps (en µs)')
ylabel('Amplitude (sans unité)')
xlim([-0.05 1.05])
ylim([-0.05 1.05])
grid on

subplot(1,2,2)
plot(t, p1)
xlabel('Temps (en µs)')
ylabel('Amplitude (sans unité)')
xlim([-0.05 1.05])
ylim([-0.05 1.05])
grid on




-----------------------------------------------------------------------
Create a Python Script Visual
(1st create a python script visual, then drag in the columns you want)
-----------------------------------------------------------------------


import numpy as np
import matplotlib.pyplot as plt
 
dataset.plot(kind = "bar")

receptions = dataset['Rec']
players = dataset['Player']
y_pos = np.arange(len(players))

plt.bar(y_pos, receptions, align='center')
plt.xticks(y_pos, players, rotation=270)
plt.ylabel('Receptions')
plt.title('Receptions by Player')
# Pad margins so that markers don't get clipped by the axes
plt.margins(0.2)
# Tweak spacing to prevent clipping of tick-labels
plt.subplots_adjust(bottom=0.35)

plt.show()

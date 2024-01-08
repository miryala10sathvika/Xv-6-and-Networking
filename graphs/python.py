import matplotlib.pyplot as plt
import re

# Read the input data from a file
with open('/home/sathvika/mini-project-2-miryala10sathvika/graphs/scheduler_data.txt', 'r') as file:
    data = file.readlines()

# Define a dictionary to store the data by queue ID
queue_data = {}

# Define a regular expression pattern to extract relevant information
pattern = r'Process with PID (\d+) added to Queue (\d+) at (\d+)'

# Parse the input data and organize it by queue ID
for line in data:
    match = re.match(pattern, line)
    if match:
        pid, queue_id, time = map(int, match.groups())
        if pid not in queue_data:
            queue_data[pid] = {'queues': [], 'times': []}
        queue_data[pid]['queues'].append(queue_id)
        queue_data[pid]['times'].append(time)

# Create a color map for processes based on unique PIDs
unique_pids = list(queue_data.keys())
colors = plt.cm.get_cmap('tab20', len(unique_pids))

# Plot the timeline graph with lines connecting points for the same process
fig, ax = plt.subplots()
legend_labels = {}  # To store legend labels

for pid, process_info in queue_data.items():
    queues = process_info['queues']
    times = process_info['times']
    pid_color = colors(unique_pids.index(pid))
    ax.plot(times, queues, '-', c=pid_color, label=f'Process {pid}', linewidth=1.0)  # Connect points with lines
    if pid not in legend_labels:
        legend_labels[pid] = f'Process {pid}'

ax.set_xlabel('Time Elapsed')
ax.set_ylabel('Queue ID')
ax.set_title('MLFQ Scheduler Timeline [AGETICKS : 28]')
ax.grid(True)

# Sort legend labels by process ID
legend_labels_sorted = [legend_labels[pid] for pid in sorted(legend_labels.keys())]
ax.legend(loc='upper right', labels=legend_labels_sorted, title='Process IDs')


plt.show()

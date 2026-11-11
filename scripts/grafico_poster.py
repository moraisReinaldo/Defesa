import matplotlib.pyplot as plt

labels = ["Backend (3)", "Frontend (2)", "Banco de dados (1)",
          "MinIO (1)", "Nginx LB (1)", "Visualizer (1)"]
valores = [3, 2, 1, 1, 1, 1]
cores = ["#003366", "#FF6600", "#4A7BA7", "#8FD3C8", "#8C8C8C", "#FFB470"]

fig, ax = plt.subplots(figsize=(6, 4.5), dpi=300)
ax.pie(valores, colors=cores, startangle=90, counterclock=False,
       autopct=lambda p: f"{p:.1f}%".replace(".", ","),
       textprops={"fontsize": 12, "color": "white", "fontweight": "bold"},
       wedgeprops={"edgecolor": "white", "linewidth": 1.5})
ax.legend(labels, loc="center left", bbox_to_anchor=(1, 0.5),
          fontsize=12, frameon=False)
ax.axis("equal")
plt.savefig("grafico_replicas.png", bbox_inches="tight", transparent=False,
            facecolor="white")

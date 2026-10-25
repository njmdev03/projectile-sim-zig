import { useEffect, useRef } from "react";

export default function Game() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const script = document.createElement("script");
    script.type = "module";
    script.textContent = `
      import createApp from "/game/projectile_sim_zig.js";

      createApp({
        canvas: document.getElementById("canvas"),
        locateFile: (path) => "/game/" + path.split("/").pop(),
      });
    `;

    document.body.appendChild(script);

    return () => script.remove();
  }, []);

  return (
    <div className="game-container">
      <canvas ref={canvasRef} id="canvas" />
    </div>
  );
}

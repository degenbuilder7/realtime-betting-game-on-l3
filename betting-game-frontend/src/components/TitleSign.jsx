import { useEffect } from "react";

export default function TitleSign() {
  useEffect(() => {
    var titleLetter = document.querySelector(
      `h1 span:nth-of-type(${Math.floor(Math.random() * 8) + 1})`
    );
    titleLetter.classList.add("flicker-animation");

    var titleLetter2 = document.querySelector(
      `h1 span:nth-of-type(${Math.floor(Math.random() * 8) + 1})`
    );
    titleLetter2.classList.add("flicker-animation2");
  });
  return (
    <h1 className="attention-voice flicker-in-2">
      <span>B</span>
      <span>E</span>
      <span>T</span>
      <span>T</span>
      <span>I</span>
      <span>N</span>
      <span>G</span>
      <span>G</span>
      <span>A</span>
      <span>M</span>
      <span>E</span>
      <span>ON</span>
      <span>L3</span>
    </h1>
  );
}

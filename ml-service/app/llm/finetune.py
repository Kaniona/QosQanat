"""QosQanat ұстаз LLM — LoRA fine-tuning қаңқасы (Transformers + PEFT + Datasets).

МАҢЫЗДЫ: бұл нөлден LLM жаттықтырмайды (миллиондаған $ + GPU). Оның орнына
дайын КӨП ТІЛДІ базалық модельді LoRA-мен (параметр-тиімді) оқу бағдарламасы
негізіндегі нұсқаулық деректе бейімдейді. GPU + иесінің дерегі қажет.

Деректі құру (build_instruction_dataset/format_chat) — таза Python, осы жерде
жүгіреді; жаттықтыру (train_lora) — ауыр кітапханаларды лениво импорттайды.
"""
from __future__ import annotations

import json
from pathlib import Path

DEFAULT_BASE_MODEL = "Qwen/Qwen2.5-1.5B-Instruct"  # көп тілді, шағын база

SYSTEM_PROMPT = (
    "Сен — QosQanат оқу қосымшасының достық ұстазысың. Оқушыға қазақ тілінде, "
    "қысқа әрі түсінікті жауап бер. Жауапты дайын бермей, қадаммен жетеле. "
    "Тек оқу тақырыптары бойынша көмектес."
)


def build_instruction_dataset(lessons):
    """Сабақтардан нұсқаулық–жауап жұптарын құрады (LLM-ді үйрету деректі)."""
    examples = []
    for lesson in lessons:
        title = lesson.get("title", "")
        intro = lesson.get("intro", "")
        formula = lesson.get("formula", "")
        response = intro + (f"\n\nФормула: {formula}" if formula else "")
        for template in (
            f"«{title}» дегеніміз не?",
            f"{title} тақырыбын түсіндірші.",
            f"{title} туралы қысқаша айтып бер.",
        ):
            examples.append({"instruction": template, "response": response})
    return examples


def format_chat(example: dict) -> str:
    """Чат форматы (ChatML тәрізді)."""
    return (
        f"<|system|>\n{SYSTEM_PROMPT}\n"
        f"<|user|>\n{example['instruction']}\n"
        f"<|assistant|>\n{example['response']}\n<|end|>"
    )


def export_dataset(lessons, out_path: str) -> int:
    """Нұсқаулық деректі JSONL етіп жазу (жаттығу үшін)."""
    examples = build_instruction_dataset(lessons)
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as fh:
        for ex in examples:
            fh.write(json.dumps({"text": format_chat(ex)}, ensure_ascii=False) + "\n")
    return len(examples)


def train_lora(
    dataset_jsonl: str,
    base_model: str = DEFAULT_BASE_MODEL,
    output_dir: str = "tutor-lora",
    epochs: int = 3,
    lora_r: int = 16,
    lora_alpha: int = 32,
    lr: float = 2e-4,
):
    """LoRA адаптерін жаттықтыру (GPU қажет). Ауыр кітапханалар лениво импортталады."""
    import torch
    from datasets import load_dataset
    from peft import LoraConfig, get_peft_model
    from transformers import (
        AutoModelForCausalLM,
        AutoTokenizer,
        DataCollatorForLanguageModeling,
        Trainer,
        TrainingArguments,
    )

    tokenizer = AutoTokenizer.from_pretrained(base_model)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        base_model, torch_dtype=torch.float16, device_map="auto"
    )
    lora = LoraConfig(
        r=lora_r,
        lora_alpha=lora_alpha,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
        lora_dropout=0.05,
        task_type="CAUSAL_LM",
    )
    model = get_peft_model(model, lora)
    model.print_trainable_parameters()

    ds = load_dataset("json", data_files=dataset_jsonl, split="train")
    ds = ds.map(
        lambda b: tokenizer(b["text"], truncation=True, max_length=512),
        batched=True,
        remove_columns=ds.column_names,
    )

    args = TrainingArguments(
        output_dir=output_dir,
        num_train_epochs=epochs,
        per_device_train_batch_size=4,
        gradient_accumulation_steps=4,
        learning_rate=lr,
        fp16=True,
        logging_steps=10,
        save_strategy="epoch",
    )
    trainer = Trainer(
        model=model,
        args=args,
        train_dataset=ds,
        data_collator=DataCollatorForLanguageModeling(tokenizer, mlm=False),
    )
    trainer.train()
    model.save_pretrained(output_dir)
    tokenizer.save_pretrained(output_dir)
    return output_dir

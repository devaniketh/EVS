interface CardProps {
  title: string;
  description: string;
}

function Card({ title, description }: CardProps) {
  return (
    <div className="w-1/3 h-90 border-4 border-primary overflow-hidden p-6 flex items-end gap-4">
      <h1 className="font-head uppercase font-bold text-5xl">{title}</h1>
      <p className="text-right hidden">{description}</p>
    </div>
  );
}

export default function Steps() {
  return (
    <section className="py-20">
      <div className="container mx-auto">
        <div className="flex justify-center items-center gap-8">
          <Card
            title="Play"
            description="Lorem ipsum dolor sit amet consectetur adipisicing elit. Fugiat enim, itaque."
          />
          <Card
            title="Earn"
            description="Lorem ipsum dolor sit amet consectetur adipisicing elit. Fugiat enim, itaque."
          />
          <Card
            title="Trade"
            description="Lorem ipsum dolor sit amet consectetur adipisicing elit. Fugiat enim, itaque."
          />
        </div>
      </div>
    </section>
  );
}

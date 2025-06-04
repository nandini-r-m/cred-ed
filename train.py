from chatterbot import ChatBot
from chatterbot.trainers import ChatterBotCorpusTrainer

chatbot = ChatBot('SafetyBot', database_uri='sqlite:///db.sqlite3')

trainer = ChatterBotCorpusTrainer(chatbot)
trainer.train("./custom_corpus/safety.yml")

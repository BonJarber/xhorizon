import os
from celery import Celery

celery_app = Celery("worker", broker=f"amqp://guest@{os.environ['QUEUE_ENDPOINT']}//")

celery_app.conf.task_routes = {"app.worker.test_celery": "main-queue"}
